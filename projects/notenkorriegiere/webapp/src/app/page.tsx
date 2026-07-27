'use client';

import React, { useState, useEffect } from 'react';
import Sidebar from '../components/Sidebar';
import Wissensdatenbank from '../components/Wissensdatenbank';
import Klausurerstellung from '../components/Klausurerstellung';
import KorrekturBewertung from '../components/KorrekturBewertung';
import FeedbackDashboard from '../components/FeedbackDashboard';
import { 
  getInitialState, 
  saveState, 
  Class, 
  Document, 
  Question, 
  Exam, 
  Submission, 
  Evaluation 
} from '../lib/store';

export default function Dashboard() {
  const [activeTab, setActiveTab] = useState('rag');
  const [state, setState] = useState<{
    classes: Class[];
    documents: Document[];
    exams: Exam[];
    submissions: Submission[];
    evaluations: Evaluation[];
  } | null>(null);

  // Initialize state from LocalStorage on mount
  useEffect(() => {
    setState(getInitialState());
  }, []);

  // Sync state changes with LocalStorage
  const updateState = (updater: (prev: typeof state) => typeof state) => {
    setState(prev => {
      if (!prev) return prev;
      const next = updater(prev);
      if (next) saveState(next);
      return next;
    });
  };

  if (!state) {
    return (
      <div className="flex-1 min-h-screen bg-black flex items-center justify-center text-zinc-400 font-medium">
        Lade Dashboard...
      </div>
    );
  }

  // Tab 1 handlers: Documents
  const handleUploadDocument = (title: string, pageCount: number) => {
    updateState(prev => {
      if (!prev) return prev;
      const newDoc: Document = {
        id: `doc_${Date.now()}`,
        title,
        pageCount,
        createdAt: new Date().toISOString(),
      };
      return {
        ...prev,
        documents: [...prev.documents, newDoc]
      };
    });
  };

  const handleDeleteDocument = (id: string) => {
    updateState(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        documents: prev.documents.filter(d => d.id !== id)
      };
    });
  };

  // Tab 2 handlers: Exams
  const handleCreateExam = (title: string, description: string, questions: Question[]) => {
    updateState(prev => {
      if (!prev) return prev;
      const newExam: Exam = {
        id: `exam_${Date.now()}`,
        title,
        description,
        classId: prev.classes[0]?.id || 'c1',
        status: 'draft',
        questions,
        createdAt: new Date().toISOString(),
      };
      return {
        ...prev,
        exams: [...prev.exams, newExam]
      };
    });
  };

  const handleUpdateExam = (updatedExam: Exam) => {
    updateState(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        exams: prev.exams.map(e => e.id === updatedExam.id ? updatedExam : e)
      };
    });
  };

  const handleDeleteExam = (id: string) => {
    updateState(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        exams: prev.exams.filter(e => e.id !== id)
      };
    });
  };

  // Tab 3 handlers: Submissions
  const handleAddSubmission = (submission: Submission, evaluations: Evaluation[]) => {
    updateState(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        submissions: [submission, ...prev.submissions],
        evaluations: [...prev.evaluations, ...evaluations]
      };
    });
  };

  // Tab 4 handlers: Feedback Dashboard
  const handleUpdateEvaluation = (updatedEval: Evaluation) => {
    updateState(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        evaluations: prev.evaluations.map(ev => ev.id === updatedEval.id ? updatedEval : ev)
      };
    });
  };

  const handleUpdateSubmissionScore = (submissionId: string, newScore: number) => {
    updateState(prev => {
      if (!prev) return prev;
      return {
        ...prev,
        submissions: prev.submissions.map(sub => 
          sub.id === submissionId ? { ...sub, totalScore: newScore } : sub
        )
      };
    });
  };

  return (
    <div className="flex min-h-screen bg-zinc-950 font-sans text-zinc-200 antialiased overflow-hidden">
      {/* Sidebar Layout */}
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col h-screen overflow-y-auto bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-indigo-950/20 via-zinc-950 to-zinc-950">
        
        {/* Glow ambient background decoration */}
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-violet-600/5 rounded-full blur-[120px] pointer-events-none"></div>
        <div className="absolute bottom-0 left-80 w-[400px] h-[400px] bg-indigo-600/5 rounded-full blur-[100px] pointer-events-none"></div>

        {/* Global Toolbar Header */}
        <header className="border-b border-zinc-900 bg-zinc-950/70 backdrop-blur-md sticky top-0 z-40 px-8 py-4 flex items-center justify-between select-none">
          <div className="flex items-center gap-3">
            <span className="text-xs font-semibold bg-violet-500/10 text-violet-400 border border-violet-500/20 px-2.5 py-1 rounded-full">
              Demo Workspace
            </span>
            <span className="text-zinc-600">|</span>
            <span className="text-xs text-zinc-500 font-medium">Aktives Fach: Mathematik (10a)</span>
          </div>
          <div className="flex items-center gap-4 text-xs font-medium text-zinc-400">
            <span>Status: <b>Verbunden mit Supabase Mock-DB</b></span>
          </div>
        </header>

        {/* View Router */}
        <div className="flex-1 px-8 py-8 relative max-w-7xl w-full mx-auto pb-16">
          {activeTab === 'rag' && (
            <Wissensdatenbank 
              documents={state.documents} 
              onUpload={handleUploadDocument} 
              onDelete={handleDeleteDocument} 
            />
          )}

          {activeTab === 'exams' && (
            <Klausurerstellung 
              exams={state.exams}
              documents={state.documents}
              onCreateExam={handleCreateExam}
              onUpdateExam={handleUpdateExam}
              onDeleteExam={handleDeleteExam}
            />
          )}

          {activeTab === 'grading' && (
            <KorrekturBewertung 
              exams={state.exams}
              submissions={state.submissions}
              onAddSubmission={handleAddSubmission}
            />
          )}

          {activeTab === 'feedback' && (
            <FeedbackDashboard 
              exams={state.exams}
              submissions={state.submissions}
              evaluations={state.evaluations}
              onUpdateEvaluation={handleUpdateEvaluation}
              onUpdateSubmissionScore={handleUpdateSubmissionScore}
            />
          )}
        </div>
      </main>
    </div>
  );
}
