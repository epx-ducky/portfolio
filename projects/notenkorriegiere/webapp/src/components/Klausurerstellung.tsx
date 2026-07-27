'use client';

import React, { useState } from 'react';
import { 
  Sparkles, 
  Plus, 
  Trash2, 
  Edit3, 
  Save, 
  Check, 
  HelpCircle,
  FileText,
  Bookmark,
  ChevronDown,
  Printer
} from 'lucide-react';
import { Exam, Question, Document } from '../lib/store';

interface KlausurerstellungProps {
  exams: Exam[];
  documents: Document[];
  onCreateExam: (title: string, description: string, questions: Question[]) => void;
  onUpdateExam: (updatedExam: Exam) => void;
  onDeleteExam: (id: string) => void;
}

export default function Klausurerstellung({ 
  exams, 
  documents, 
  onCreateExam, 
  onUpdateExam, 
  onDeleteExam 
}: KlausurerstellungProps) {
  const [selectedExamId, setSelectedExamId] = useState<string>(exams[0]?.id || '');
  const [isGenerating, setIsGenerating] = useState(false);
  const [promptText, setPromptText] = useState('');
  const [selectedDocId, setSelectedDocId] = useState(documents[0]?.id || '');
  const [questionCount, setQuestionCount] = useState(3);
  const [examTitle, setExamTitle] = useState('');
  const [examDesc, setExamDesc] = useState('');

  // Editing state
  const [editingQuestionId, setEditingQuestionId] = useState<string | null>(null);
  const [editedText, setEditedText] = useState('');
  const [editedPoints, setEditedPoints] = useState(0);
  const [editedAnswer, setEditedAnswer] = useState('');

  const currentExam = exams.find(e => e.id === selectedExamId);

  const handleGenerateExam = (e: React.FormEvent) => {
    e.preventDefault();
    if (!promptText) return;

    setIsGenerating(true);

    // Simulate AI generation matching the RAG context
    setTimeout(() => {
      const generatedTitle = examTitle || `Klassenarbeit: ${promptText.slice(0, 25)}...`;
      const generatedDesc = examDesc || `Generiert basierend auf RAG-Kontext. Fokus: ${promptText}`;
      
      const mockQuestions: Question[] = Array.from({ length: questionCount }).map((_, i) => ({
        id: `gen_q_${Date.now()}_${i}`,
        questionText: `Generierte Frage ${i + 1} über "${promptText}": Erläutere das Kernprinzip und nenne ein Beispiel.`,
        maxPoints: Math.random() > 0.5 ? 4 : 2,
        expectedAnswer: `Dies ist der generierte Erwartungshorizont für Frage ${i + 1}. Ein guter Schüler sollte Kernpunkte A, B und C nennen.`,
      }));

      onCreateExam(generatedTitle, generatedDesc, mockQuestions);
      setIsGenerating(false);
      setPromptText('');
      setExamTitle('');
      setExamDesc('');
      
      // Auto select the new exam
      // (The parent will append to list, let's auto-select in the next render cycle)
    }, 2000);
  };

  const startEditQuestion = (q: Question) => {
    setEditingQuestionId(q.id);
    setEditedText(q.questionText);
    setEditedPoints(q.maxPoints);
    setEditedAnswer(q.expectedAnswer);
  };

  const saveEditedQuestion = () => {
    if (!currentExam || !editingQuestionId) return;

    const updatedQuestions = currentExam.questions.map(q => {
      if (q.id === editingQuestionId) {
        return {
          ...q,
          questionText: editedText,
          maxPoints: editedPoints,
          expectedAnswer: editedAnswer
        };
      }
      return q;
    });

    onUpdateExam({
      ...currentExam,
      questions: updatedQuestions
    });

    setEditingQuestionId(null);
  };

  const addEmptyQuestion = () => {
    if (!currentExam) return;

    const newQuestion: Question = {
      id: `manual_q_${Date.now()}`,
      questionText: 'Neue Frage hier eingeben...',
      maxPoints: 4,
      expectedAnswer: 'Musterlösung / Erwartungshorizont hier eingeben...'
    };

    onUpdateExam({
      ...currentExam,
      questions: [...currentExam.questions, newQuestion]
    });
  };

  const deleteQuestion = (questionId: string) => {
    if (!currentExam) return;

    onUpdateExam({
      ...currentExam,
      questions: currentExam.questions.filter(q => q.id !== questionId)
    });
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      {/* Sidebar: Generator Form */}
      <div className="lg:col-span-4 bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-5 space-y-6 backdrop-blur-xl">
        <div>
          <h3 className="font-bold text-white text-base flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-violet-400" />
            Klausur-Generator
          </h3>
          <p className="text-zinc-500 text-xs mt-1">
            Nutze die KI, um eine Klausur direkt aus deinen Wissensdokumenten erstellen zu lassen.
          </p>
        </div>

        <form onSubmit={handleGenerateExam} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-zinc-400">RAG-Kontext wählen</label>
            <select
              value={selectedDocId}
              onChange={(e) => setSelectedDocId(e.target.value)}
              className="w-full px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl text-xs text-white focus:outline-none focus:border-zinc-700"
            >
              {documents.length === 0 ? (
                <option value="">Keine Dokumente vorhanden</option>
              ) : (
                documents.map(doc => (
                  <option key={doc.id} value={doc.id}>{doc.title}</option>
                ))
              )}
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-zinc-400">Klausur Titel (Optional)</label>
            <input
              type="text"
              placeholder="z.B. 2. Klausur Geometrie"
              value={examTitle}
              onChange={(e) => setExamTitle(e.target.value)}
              className="w-full px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl text-xs text-white placeholder-zinc-650 focus:outline-none focus:border-zinc-700"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-zinc-400">KI-Prompt (Zielthemen & Fokus)</label>
            <textarea
              placeholder="z.B. Erstelle Fragen zu Steigungsdreiecken und Schnittpunktberechnungen. Die Fragen sollen für eine 10. Klasse angemessen sein."
              value={promptText}
              onChange={(e) => setPromptText(e.target.value)}
              rows={3}
              required
              className="w-full px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-zinc-700 resize-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-zinc-400">Anzahl Fragen</label>
              <input
                type="number"
                min={1}
                max={15}
                value={questionCount}
                onChange={(e) => setQuestionCount(parseInt(e.target.value))}
                className="w-full px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl text-xs text-white focus:outline-none focus:border-zinc-700"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-zinc-400">Schwierigkeit</label>
              <select className="w-full px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl text-xs text-white focus:outline-none focus:border-zinc-700">
                <option>Mittel</option>
                <option>Leicht</option>
                <option>Schwer</option>
              </select>
            </div>
          </div>

          <button
            type="submit"
            disabled={isGenerating || documents.length === 0}
            className="w-full py-2.5 bg-gradient-to-r from-violet-600 to-indigo-600 hover:from-violet-500 hover:to-indigo-500 text-white rounded-xl text-xs font-semibold transition-all duration-300 flex items-center justify-center gap-2 shadow-md shadow-indigo-650/20 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isGenerating ? (
              <>
                <Sparkles className="w-4 h-4 animate-spin" />
                <span>Generiere Klausur...</span>
              </>
            ) : (
              <>
                <Sparkles className="w-4 h-4" />
                <span>Klausur generieren</span>
              </>
            )}
          </button>
        </form>
      </div>

      {/* Main Panel: Editor */}
      <div className="lg:col-span-8 space-y-6">
        {/* Selector & Actions */}
        <div className="bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 backdrop-blur-xl">
          <div className="space-y-1">
            <span className="text-xs font-semibold text-zinc-500 uppercase tracking-wider">Klausur auswählen</span>
            <div className="relative">
              <select
                value={selectedExamId}
                onChange={(e) => setSelectedExamId(e.target.value)}
                className="appearance-none w-64 pr-10 pl-3 py-1.5 bg-zinc-900 border border-zinc-800 rounded-xl text-xs font-semibold text-white focus:outline-none focus:border-zinc-700"
              >
                {exams.map(e => (
                  <option key={e.id} value={e.id}>{e.title}</option>
                ))}
              </select>
              <ChevronDown className="w-3.5 h-3.5 text-zinc-500 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            </div>
          </div>

          {currentExam && (
            <div className="flex items-center gap-2">
              <button
                onClick={() => window.print()}
                className="text-xs font-semibold bg-violet-600 hover:bg-violet-500 text-white px-3 py-1.5 rounded-lg transition-colors flex items-center gap-1.5 shadow"
              >
                <Printer className="w-3.5 h-3.5" />
                <span>PDF generieren</span>
              </button>
              <button
                onClick={() => onDeleteExam(currentExam.id)}
                className="text-xs font-semibold text-red-400 hover:text-red-300 px-3 py-1.5 rounded-lg border border-red-500/10 hover:bg-red-500/10 transition-colors"
              >
                Klausur löschen
              </button>
            </div>
          )}
        </div>

        {/* Editor Board */}
        {currentExam ? (
          <div className="bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-6 space-y-6 backdrop-blur-xl">
            <div className="border-b border-zinc-800 pb-4 flex justify-between items-start">
              <div>
                <h3 className="text-xl font-bold text-white">{currentExam.title}</h3>
                <p className="text-zinc-500 text-xs mt-1">{currentExam.description}</p>
              </div>
              <div className="text-right">
                <span className="text-2xl font-black text-violet-400">
                  {currentExam.questions.reduce((acc, q) => acc + q.maxPoints, 0)}
                </span>
                <span className="text-xs text-zinc-500 block font-semibold">Punkte Gesamt</span>
              </div>
            </div>

            {/* Questions list */}
            <div className="space-y-4">
              {currentExam.questions.map((q, idx) => (
                <div 
                  key={q.id} 
                  className={`border rounded-xl p-4 transition-all ${
                    editingQuestionId === q.id 
                      ? 'border-violet-500 bg-violet-500/5' 
                      : 'border-zinc-800 hover:border-zinc-700 bg-zinc-900/10'
                  }`}
                >
                  {editingQuestionId === q.id ? (
                    /* Edit mode */
                    <div className="space-y-4">
                      <div className="flex justify-between items-center">
                        <span className="text-xs font-bold text-violet-400">Bearbeite Frage {idx + 1}</span>
                        <div className="flex items-center gap-1.5">
                          <label className="text-xs text-zinc-400 font-semibold">Punkte:</label>
                          <input
                            type="number"
                            value={editedPoints}
                            onChange={(e) => setEditedPoints(parseInt(e.target.value) || 0)}
                            className="w-16 px-2 py-0.5 bg-zinc-900 border border-zinc-800 rounded-md text-xs text-white text-center focus:outline-none"
                          />
                        </div>
                      </div>

                      <div className="space-y-1">
                        <label className="text-xs font-semibold text-zinc-500">Fragetext</label>
                        <textarea
                          value={editedText}
                          onChange={(e) => setEditedText(e.target.value)}
                          rows={2}
                          className="w-full px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-lg text-xs text-white focus:outline-none"
                        />
                      </div>

                      <div className="space-y-1">
                        <label className="text-xs font-semibold text-zinc-500">Erwartungshorizont (Lösung)</label>
                        <textarea
                          value={editedAnswer}
                          onChange={(e) => setEditedAnswer(e.target.value)}
                          rows={3}
                          className="w-full px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-lg text-xs text-white focus:outline-none"
                        />
                      </div>

                      <div className="flex justify-end gap-2 pt-2">
                        <button
                          onClick={() => setEditingQuestionId(null)}
                          className="px-3 py-1.5 text-zinc-500 hover:text-zinc-300 text-xs font-semibold transition-colors"
                        >
                          Abbrechen
                        </button>
                        <button
                          onClick={saveEditedQuestion}
                          className="px-3 py-1.5 bg-violet-600 hover:bg-violet-500 text-white rounded-lg text-xs font-semibold transition-colors flex items-center gap-1.5"
                        >
                          <Check className="w-3.5 h-3.5" />
                          Speichern
                        </button>
                      </div>
                    </div>
                  ) : (
                    /* Read mode */
                    <div className="space-y-3">
                      <div className="flex justify-between items-start gap-4">
                        <div className="space-y-1">
                          <span className="text-xs font-semibold text-zinc-500">Frage {idx + 1}</span>
                          <p className="text-sm font-semibold text-white">{q.questionText}</p>
                        </div>
                        <div className="flex items-center gap-3 flex-shrink-0">
                          <span className="text-xs font-bold bg-zinc-800 px-2 py-1 rounded text-zinc-400">
                            {q.maxPoints} {q.maxPoints === 1 ? 'Punkt' : 'Punkte'}
                          </span>
                          <div className="flex gap-1">
                            <button
                              onClick={() => startEditQuestion(q)}
                              className="p-1 text-zinc-500 hover:text-white transition-colors"
                            >
                              <Edit3 className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => deleteQuestion(q.id)}
                              className="p-1 text-zinc-500 hover:text-red-400 transition-colors"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </div>
                      </div>

                      <div className="bg-zinc-950/40 rounded-lg p-3 border border-zinc-800/40">
                        <span className="text-xs font-bold text-indigo-400 flex items-center gap-1.5 mb-1">
                          <Bookmark className="w-3 h-3" />
                          Erwartungshorizont (Musterlösung):
                        </span>
                        <p className="text-xs text-zinc-400 leading-relaxed whitespace-pre-line">{q.expectedAnswer}</p>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>

            <button
              onClick={addEmptyQuestion}
              className="w-full py-3 border border-dashed border-zinc-800 hover:border-zinc-700 hover:bg-zinc-900/10 text-zinc-500 hover:text-zinc-300 rounded-xl text-xs font-semibold transition-all flex items-center justify-center gap-2"
            >
              <Plus className="w-4 h-4" />
              <span>Frage manuell hinzufügen</span>
            </button>
          </div>
        ) : (
          <div className="bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-12 text-center text-zinc-500 backdrop-blur-xl">
            Keine Klausuren vorhanden. Erstelle eine über den Generator auf der linken Seite.
          </div>
        )}
      </div>

      {/* -------------------- PRINT-ONLY TEMPLATE -------------------- */}
      {currentExam && (
        <div className="print-only w-full text-black p-8 font-sans">
          {/* Header metadata */}
          <div className="flex justify-between items-start border-b-2 border-black pb-4 mb-6">
            <div>
              <h1 className="text-xl font-bold uppercase tracking-wide">Klassenarbeit / Klausur</h1>
              <p className="text-sm font-semibold mt-1">Fach: Mathematik</p>
            </div>
            <div className="grid grid-cols-2 gap-x-6 gap-y-2 text-xs font-semibold">
              <div>Name: ______________________</div>
              <div>Datum: __________________</div>
              <div>Klasse: ____________________</div>
              <div>Punkte: ______ / {currentExam.questions.reduce((acc, q) => acc + q.maxPoints, 0)} P.</div>
            </div>
          </div>

          {/* Exam Info */}
          <div className="mb-6">
            <h2 className="text-2xl font-bold">{currentExam.title}</h2>
            {currentExam.description && (
              <p className="text-xs text-gray-650 mt-1 italic">{currentExam.description}</p>
            )}
          </div>

          {/* Questions list with blank writing lines */}
          <div className="space-y-8">
            {currentExam.questions.map((q, idx) => {
              // Determine writing lines based on max points (e.g. 3 lines per point)
              const lineCount = Math.max(3, q.maxPoints * 3);
              return (
                <div key={q.id} className="print-no-break space-y-3">
                  <div className="flex justify-between items-baseline font-bold border-b border-gray-300 pb-1">
                    <span className="text-sm">Aufgabe {idx + 1}: {q.questionText}</span>
                    <span className="text-xs shrink-0 pl-4 font-mono">({q.maxPoints} P.)</span>
                  </div>
                  
                  {/* Empty writing lines */}
                  <div className="space-y-4.5 pt-2">
                    {Array.from({ length: lineCount }).map((_, lineIdx) => (
                      <div key={lineIdx} className="border-b border-gray-300 h-6 w-full"></div>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
