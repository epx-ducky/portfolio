import Foundation
import Network
import SwiftData

public final class LocalAPIServer {
    public static let shared = LocalAPIServer()
    
    private var listener: NWListener?
    private var modelContext: ModelContext?
    private let queue = DispatchQueue(label: "omnia.LocalAPIServer")
    
    private init() {}
    
    public func start(modelContext: ModelContext, port: UInt16 = 8080) {
        self.modelContext = modelContext
        
        do {
            let nwPort = NWEndpoint.Port(rawValue: port)!
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: nwPort)
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Local API Server running on port \(port)")
                case .failed(let error):
                    print("Local API Server failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: queue)
            
        } catch {
            print("Failed to start Local API Server: \(error)")
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequest(connection: connection)
    }
    
    private func receiveRequest(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self, let data = data, error == nil else {
                connection.cancel()
                return
            }
            
            let requestString = String(decoding: data, as: UTF8.self)
            self.processRequest(requestString, connection: connection)
        }
    }
    
    private func processRequest(_ request: String, connection: NWConnection) {
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            sendResponse(status: "400 Bad Request", body: "Empty request", connection: connection)
            return
        }
        
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            sendResponse(status: "400 Bad Request", body: "Invalid request line", connection: connection)
            return
        }
        
        let method = parts[0]
        let path = parts[1]
        
        // Extract HTTP body if POST/PUT
        var body = ""
        if method == "POST" || method == "PUT" {
            if let index = lines.firstIndex(of: "") {
                body = lines[(index + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        Task { @MainActor in
            guard let context = self.modelContext else {
                self.sendResponse(status: "500 Internal Server Error", body: "ModelContext not initialized", connection: connection)
                return
            }
            
            let formatter = ISO8601DateFormatter()
            
            if path == "/events" && method == "GET" {
                // Return calendar events as JSON
                let fetch = FetchDescriptor<CalendarEvent>()
                if let events = try? context.fetch(fetch) {
                    let responseList = events.map { event in
                        CalendarEventResponse(
                            id: event.id.uuidString,
                            title: event.title,
                            startDate: formatter.string(from: event.startDate),
                            endDate: formatter.string(from: event.endDate),
                            associatedActivityID: event.associatedActivityID?.uuidString,
                            isAISuggested: event.isAISuggested,
                            isAccepted: event.isAccepted,
                            eventType: event.eventType.rawValue,
                            isWeeklyRecurring: event.isWeeklyRecurring,
                            cancelledDates: Array(event.cancelledDates)
                        )
                    }
                    if let jsonData = try? JSONEncoder().encode(responseList),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        self.sendResponse(status: "200 OK", body: jsonString, contentType: "application/json", connection: connection)
                        return
                    }
                }
                self.sendResponse(status: "500 Internal Server Error", body: "Failed to fetch events", connection: connection)
                
            } else if path == "/events" && method == "POST" {
                // Add new calendar event
                if let bodyData = body.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    if let rawEvent = try? decoder.decode(CalendarEventDTO.self, from: bodyData) {
                        let newEvent = CalendarEvent(
                            title: rawEvent.title,
                            startDate: rawEvent.startDate,
                            endDate: rawEvent.endDate,
                            associatedActivityID: rawEvent.associatedActivityID,
                            isAISuggested: rawEvent.isAISuggested ?? false,
                            isAccepted: rawEvent.isAccepted ?? false,
                            eventType: rawEvent.eventType,
                            isWeeklyRecurring: rawEvent.isWeeklyRecurring ?? false
                        )
                        context.insert(newEvent)
                        try? context.save()
                        
                        // Re-run scheduler to update focus activities around the new event
                        if let activities = try? context.fetch(FetchDescriptor<Activity>()) {
                            CalendarScheduler.shared.proactivelyScheduleTasks(tasks: activities, modelContext: context)
                        }
                        
                        self.sendResponse(status: "201 Created", body: "{\"status\":\"created\",\"id\":\"\(newEvent.id.uuidString)\"}", contentType: "application/json", connection: connection)
                        return
                    }
                }
                self.sendResponse(status: "400 Bad Request", body: "Invalid event JSON structure", connection: connection)
                
            } else if path.hasPrefix("/events/") && method == "DELETE" {
                // Delete event by title or ID
                let target = path.replacingOccurrences(of: "/events/", with: "").removingPercentEncoding ?? ""
                let fetch = FetchDescriptor<CalendarEvent>()
                if let events = try? context.fetch(fetch) {
                    let toDelete = events.filter { $0.title == target || $0.id.uuidString == target }
                    for event in toDelete {
                        context.delete(event)
                    }
                    try? context.save()
                    
                    // Re-run scheduler
                    if let activities = try? context.fetch(FetchDescriptor<Activity>()) {
                        CalendarScheduler.shared.proactivelyScheduleTasks(tasks: activities, modelContext: context)
                    }
                    
                    self.sendResponse(status: "200 OK", body: "{\"status\":\"deleted\",\"count\":\(toDelete.count)}", contentType: "application/json", connection: connection)
                    return
                }
                self.sendResponse(status: "404 Not Found", body: "Event not found", connection: connection)
                
            } else if path == "/tasks" && method == "GET" {
                // Return activities as JSON
                let fetch = FetchDescriptor<Activity>()
                if let tasks = try? context.fetch(fetch) {
                    let responseList = tasks.map { task in
                        ActivityResponse(
                            id: task.id.uuidString,
                            name: task.name,
                            dopaminePoints: task.dopaminePoints,
                            isCompletedToday: task.isCompletedToday,
                            category: task.category.rawValue,
                            dueDate: task.dueDate.map { formatter.string(from: $0) },
                            durationMinutes: task.durationMinutes
                        )
                    }
                    if let jsonData = try? JSONEncoder().encode(responseList),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        self.sendResponse(status: "200 OK", body: jsonString, contentType: "application/json", connection: connection)
                        return
                    }
                }
                self.sendResponse(status: "500 Internal Server Error", body: "Failed to fetch tasks", connection: connection)
                
            } else if path == "/tasks" && method == "POST" {
                // Create or update a task
                if let bodyData = body.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    if let rawTask = try? decoder.decode(ActivityDTO.self, from: bodyData) {
                        let newTask = Activity(
                            name: rawTask.name,
                            dopaminePoints: rawTask.dopaminePoints,
                            isCompletedToday: rawTask.isCompletedToday ?? false,
                            category: rawTask.category,
                            dueDate: rawTask.dueDate,
                            durationMinutes: rawTask.durationMinutes
                        )
                        context.insert(newTask)
                        try? context.save()
                        
                        // Run scheduler
                        if let activities = try? context.fetch(FetchDescriptor<Activity>()) {
                            CalendarScheduler.shared.proactivelyScheduleTasks(tasks: activities, modelContext: context)
                        }
                        
                        self.sendResponse(status: "201 Created", body: "{\"status\":\"created\",\"id\":\"\(newTask.id.uuidString)\"}", contentType: "application/json", connection: connection)
                        return
                    }
                }
                self.sendResponse(status: "400 Bad Request", body: "Invalid task JSON structure", connection: connection)
                
            } else if path.hasPrefix("/tasks/") && method == "DELETE" {
                // Delete task by name or ID
                let target = path.replacingOccurrences(of: "/tasks/", with: "").removingPercentEncoding ?? ""
                let fetch = FetchDescriptor<Activity>()
                if let tasks = try? context.fetch(fetch) {
                    let toDelete = tasks.filter { $0.name == target || $0.id.uuidString == target }
                    for task in toDelete {
                        context.delete(task)
                    }
                    try? context.save()
                    
                    // Re-run scheduler
                    if let activities = try? context.fetch(FetchDescriptor<Activity>()) {
                        CalendarScheduler.shared.proactivelyScheduleTasks(tasks: activities, modelContext: context)
                    }
                    
                    self.sendResponse(status: "200 OK", body: "{\"status\":\"deleted\",\"count\":\(toDelete.count)}", contentType: "application/json", connection: connection)
                    return
                }
                self.sendResponse(status: "404 Not Found", body: "Task not found", connection: connection)
                
            } else if path == "/location" && method == "GET" {
                let coords = LocationManager.shared.getCoordinates()
                let json = "{\"latitude\":\(coords.latitude),\"longitude\":\(coords.longitude)}"
                self.sendResponse(status: "200 OK", body: json, contentType: "application/json", connection: connection)
                return
            } else if path == "/" && method == "GET" {
                self.sendResponse(status: "200 OK", body: "{\"status\":\"online\",\"app\":\"PersonalManager\",\"api_version\":\"1.0\"}", contentType: "application/json", connection: connection)
            } else {
                self.sendResponse(status: "404 Not Found", body: "Endpoint not found", connection: connection)
            }
        }
    }
    
    private func sendResponse(status: String, body: String, contentType: String = "text/plain", connection: NWConnection) {
        let response = """
        HTTP/1.1 \(status)\r
        Content-Type: \(contentType); charset=utf-8\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        Connection: close\r
        \r
        \(body)
        """
        
        let data = Data(response.utf8)
        connection.send(content: data, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}

// Data Transfer Objects
struct CalendarEventDTO: Codable {
    var title: String
    var startDate: Date
    var endDate: Date
    var eventType: CalendarEventType
    var isAISuggested: Bool?
    var isAccepted: Bool?
    var isWeeklyRecurring: Bool?
    var associatedActivityID: UUID?
}

struct ActivityDTO: Codable {
    var name: String
    var dopaminePoints: Double
    var isCompletedToday: Bool?
    var category: ActivityCategory
    var dueDate: Date?
    var durationMinutes: Int
}

struct CalendarEventResponse: Codable {
    var id: String
    var title: String
    var startDate: String
    var endDate: String
    var associatedActivityID: String?
    var isAISuggested: Bool
    var isAccepted: Bool
    var eventType: String
    var isWeeklyRecurring: Bool
    var cancelledDates: [String]
}

struct ActivityResponse: Codable {
    var id: String
    var name: String
    var dopaminePoints: Double
    var isCompletedToday: Bool
    var category: String
    var dueDate: String?
    var durationMinutes: Int
}
