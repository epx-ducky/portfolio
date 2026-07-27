'use client';

import React from 'react';
import { 
  BookOpen, 
  FileText, 
  CheckSquare, 
  BarChart2, 
  GraduationCap,
  Settings,
  Layers
} from 'lucide-react';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

export default function Sidebar({ activeTab, setActiveTab }: SidebarProps) {
  const menuItems = [
    { id: 'rag', label: 'Wissensdatenbank', icon: BookOpen, description: 'RAG PDF-Kontext' },
    { id: 'exams', label: 'Klausurerstellung', icon: FileText, description: 'Fragen-Generator' },
    { id: 'grading', label: 'Korrektur & OCR', icon: CheckSquare, description: 'Anonymisiertes Scannen' },
    { id: 'feedback', label: 'Feedback & Noten', icon: BarChart2, description: 'KI-Korrektur & Sliders' },
  ];

  return (
    <aside className="w-80 bg-zinc-900 border-r border-zinc-800 text-zinc-300 flex flex-col h-screen select-none">
      {/* Brand Header */}
      <div className="p-6 border-b border-zinc-800 flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-violet-600 to-indigo-600 flex items-center justify-center shadow-lg shadow-indigo-500/20">
          <GraduationCap className="w-6 h-6 text-white" />
        </div>
        <div>
          <h1 className="font-bold text-lg text-white leading-tight">Grady AI</h1>
          <p className="text-xs text-zinc-500 font-medium">EdTech Grading & Feedback</p>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-4 py-6 space-y-1.5 overflow-y-auto">
        <div className="px-3 mb-2 text-xs font-semibold text-zinc-600 uppercase tracking-wider">
          Module
        </div>
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center gap-4 px-4 py-3 rounded-xl transition-all duration-200 text-left ${
                isActive 
                  ? 'bg-gradient-to-r from-violet-600/10 to-indigo-600/10 border-l-4 border-violet-500 text-white font-medium shadow-sm'
                  : 'hover:bg-zinc-800/50 hover:text-zinc-100 border-l-4 border-transparent'
              }`}
            >
              <Icon className={`w-5 h-5 ${isActive ? 'text-violet-400' : 'text-zinc-500'}`} />
              <div>
                <div className="text-sm font-medium">{item.label}</div>
                <div className="text-xs text-zinc-500 mt-0.5">{item.description}</div>
              </div>
            </button>
          );
        })}
      </nav>

      {/* Footer / User Profile */}
      <div className="p-4 border-t border-zinc-800 bg-zinc-950/40">
        <div className="flex items-center gap-3 px-2 py-1">
          <div className="w-9 h-9 rounded-full bg-zinc-800 border border-zinc-700 flex items-center justify-center font-bold text-sm text-zinc-300">
            DR
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-white truncate">Dr. Reuss</p>
            <p className="text-xs text-zinc-500 truncate">Gymnasium Neustadt</p>
          </div>
          <button className="text-zinc-500 hover:text-zinc-300 p-1.5 hover:bg-zinc-800 rounded-lg transition-colors">
            <Settings className="w-4 h-4" />
          </button>
        </div>
      </div>
    </aside>
  );
}
