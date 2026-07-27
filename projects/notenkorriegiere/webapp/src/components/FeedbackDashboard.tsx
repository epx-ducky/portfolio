'use client';

import React, { useState } from 'react';
import { 
  BarChart2, 
  User, 
  Award, 
  BookOpen, 
  Send, 
  Code,
  FileCode,
  CheckCircle,
  HelpCircle,
  AlertTriangle,
  HeartHandshake
} from 'lucide-react';
import { Exam, Submission, Evaluation, Question } from '../lib/store';

interface FeedbackDashboardProps {
  exams: Exam[];
  submissions: Submission[];
  evaluations: Evaluation[];
  onUpdateEvaluation: (updatedEval: Evaluation) => void;
  onUpdateSubmissionScore: (submissionId: string, newScore: number) => void;
}

export default function FeedbackDashboard({
  exams,
  submissions,
  evaluations,
  onUpdateEvaluation,
  onUpdateSubmissionScore
}: FeedbackDashboardProps) {
  const [selectedSubmissionId, setSelectedSubmissionId] = useState(submissions[0]?.id || '');
  const [activeQuestionIndex, setActiveQuestionIndex] = useState(0);
  const [showJsonPreview, setShowJsonPreview] = useState(false);

  const currentSubmission = submissions.find(s => s.id === selectedSubmissionId);
  const currentExam = exams.find(e => e.id === currentSubmission?.examId);
  
  const currentSubmissionEvaluations = evaluations.filter(
    ev => ev.submissionId === selectedSubmissionId
  );

  const currentQuestion = currentExam?.questions[activeQuestionIndex];
  const currentEvaluation = currentSubmissionEvaluations.find(
    ev => ev.questionId === currentQuestion?.id
  );

  const handleScoreChange = (newVal: number) => {
    if (!currentEvaluation || !currentSubmission) return;

    // Update evaluation score & set override tag
    const updatedEval = {
      ...currentEvaluation,
      awardedPoints: newVal,
      isOverridden: true
    };
    onUpdateEvaluation(updatedEval);

    // Recompute total score for the submission
    const otherEvals = currentSubmissionEvaluations.filter(ev => ev.questionId !== currentQuestion?.id);
    const totalPoints = otherEvals.reduce((acc, ev) => acc + ev.awardedPoints, 0) + newVal;
    onUpdateSubmissionScore(currentSubmission.id, totalPoints);
  };

  const handleTextChange = (field: 'teacherAnalysis' | 'studentFeedback', value: string) => {
    if (!currentEvaluation) return;
    onUpdateEvaluation({
      ...currentEvaluation,
      [field]: value,
      isOverridden: true
    });
  };

  const handleTutoringPlanChange = (field: 'recommendation' | 'exercise' | 'longTermTip', value: string) => {
    if (!currentEvaluation) return;
    onUpdateEvaluation({
      ...currentEvaluation,
      tutoringPlan: {
        ...currentEvaluation.tutoringPlan,
        [field]: value
      },
      isOverridden: true
    });
  };

  const getStructuredJson = () => {
    if (!currentSubmission) return '{}';
    const data = {
      submissionId: currentSubmission.id,
      studentIdentifier: currentSubmission.studentIdentifier,
      totalScore: currentSubmission.totalScore,
      evaluations: currentSubmissionEvaluations.map(ev => {
        const question = currentExam?.questions.find(q => q.id === ev.questionId);
        return {
          questionText: question?.questionText,
          maxPoints: question?.maxPoints,
          awardedPoints: ev.awardedPoints,
          isOverridden: ev.isOverridden,
          analysisForTeacher: ev.teacherAnalysis,
          feedbackForStudent: ev.studentFeedback,
          tutoringPlan: ev.tutoringPlan
        };
      })
    };
    return JSON.stringify(data, null, 2);
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      {/* Sidebar: Student submissions list */}
      <div className="lg:col-span-3 bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-5 space-y-4 backdrop-blur-xl">
        <span className="text-xs font-bold text-zinc-500 uppercase tracking-wider">Schülerabgaben</span>
        
        {submissions.length === 0 ? (
          <p className="text-zinc-500 text-xs py-4 text-center">Keine Abgaben zum Bewerten.</p>
        ) : (
          <div className="space-y-2">
            {submissions.map(sub => {
              const exam = exams.find(e => e.id === sub.examId);
              const maxPoints = exam?.questions.reduce((acc, q) => acc + q.maxPoints, 0) || 0;
              const isSelected = sub.id === selectedSubmissionId;
              
              return (
                <button
                  key={sub.id}
                  onClick={() => {
                    setSelectedSubmissionId(sub.id);
                    setActiveQuestionIndex(0);
                  }}
                  className={`w-full p-3 rounded-xl border text-left transition-all ${
                    isSelected 
                      ? 'bg-gradient-to-r from-violet-600/10 to-indigo-600/10 border-violet-500 text-white shadow-sm'
                      : 'border-zinc-800 hover:bg-zinc-850 text-zinc-400 hover:text-zinc-200'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <User className="w-4 h-4 text-zinc-500" />
                    <span className="text-xs font-semibold truncate flex-1">{sub.studentIdentifier}</span>
                  </div>
                  <div className="flex justify-between items-center mt-2.5">
                    <span className="text-[10px] text-zinc-500 truncate max-w-[120px]">{exam?.title}</span>
                    <span className="text-xs font-bold text-violet-400">
                      {sub.totalScore} / {maxPoints} P.
                    </span>
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Main Board: AI Review & Human-in-the-Loop */}
      <div className="lg:col-span-9 space-y-6">
        {currentSubmission && currentExam && currentQuestion && currentEvaluation ? (
          <>
            {/* Header: Pupil and Question Tabs */}
            <div className="bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 backdrop-blur-xl">
              <div>
                <span className="text-[10px] font-bold text-violet-400 uppercase tracking-wider">Aktiver Review</span>
                <h3 className="text-lg font-bold text-white mt-0.5">{currentSubmission.studentIdentifier}</h3>
                <p className="text-xs text-zinc-500 mt-0.5">Klausur: {currentExam.title}</p>
              </div>

              {/* Question selector tabs */}
              <div className="flex bg-zinc-950/60 p-1 rounded-xl border border-zinc-800/60">
                {currentExam.questions.map((q, idx) => {
                  const isTabActive = idx === activeQuestionIndex;
                  return (
                    <button
                      key={q.id}
                      onClick={() => setActiveQuestionIndex(idx)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                        isTabActive 
                          ? 'bg-zinc-800 text-white shadow-sm'
                          : 'text-zinc-500 hover:text-zinc-300'
                      }`}
                    >
                      Frage {idx + 1}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Active Question Grading Panel */}
            <div className="grid grid-cols-1 md:grid-cols-12 gap-6">
              {/* Left Column: Answers & Grading */}
              <div className="md:col-span-7 space-y-6">
                {/* Question and OCR Answer */}
                <div className="bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-5 space-y-4 backdrop-blur-xl">
                  <div>
                    <span className="text-xs font-semibold text-zinc-500">Fragentext:</span>
                    <p className="text-sm font-semibold text-white mt-1">{currentQuestion.questionText}</p>
                  </div>
                  <div className="border-t border-zinc-800/60 pt-3">
                    <span className="text-xs font-semibold text-zinc-500">Erkannte Schülerantwort (OCR):</span>
                    <p className="text-xs text-zinc-300 bg-zinc-950/40 border border-zinc-800/40 rounded-xl p-3 mt-1.5 italic leading-relaxed">
                      "{currentEvaluation.studentAnswerText || 'Keine Antwort erkannt.'}"
                    </p>
                  </div>
                </div>

                {/* Human-in-the-loop Adjustments */}
                <div className="bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-5 space-y-5 backdrop-blur-xl">
                  <div className="flex justify-between items-center">
                    <h4 className="font-bold text-white text-sm flex items-center gap-2">
                      <Award className="w-4.5 h-4.5 text-violet-400" />
                      Bewertung & Punkte
                    </h4>
                    {currentEvaluation.isOverridden && (
                      <span className="text-[10px] font-bold bg-amber-500/10 text-amber-400 border border-amber-500/20 px-2 py-0.5 rounded-full flex items-center gap-1">
                        <AlertTriangle className="w-3 h-3" />
                        Manuell angepasst
                      </span>
                    )}
                  </div>

                  {/* Slider */}
                  <div className="space-y-2">
                    <div className="flex justify-between text-xs font-semibold text-zinc-400">
                      <span>Vergebene Punkte:</span>
                      <span className="text-violet-400 font-bold">{currentEvaluation.awardedPoints} / {currentQuestion.maxPoints} Punkte</span>
                    </div>
                    <input
                      type="range"
                      min={0}
                      max={currentQuestion.maxPoints}
                      step={0.5}
                      value={currentEvaluation.awardedPoints}
                      onChange={(e) => handleScoreChange(parseFloat(e.target.value))}
                      className="w-full h-1.5 bg-zinc-800 rounded-lg appearance-none cursor-pointer accent-violet-500"
                    />
                    <div className="flex justify-between text-[10px] text-zinc-500 font-bold">
                      <span>0 Punkte</span>
                      <span>{currentQuestion.maxPoints} Punkte</span>
                    </div>
                  </div>

                  {/* Teacher Analysis */}
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-zinc-400">Sachliche KI-Analyse (für Lehrkraft)</label>
                    <textarea
                      value={currentEvaluation.teacherAnalysis}
                      onChange={(e) => handleTextChange('teacherAnalysis', e.target.value)}
                      rows={3}
                      className="w-full px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-zinc-700"
                    />
                  </div>

                  {/* Empathic Student Feedback */}
                  <div className="space-y-1.5">
                    <label className="text-xs font-semibold text-zinc-400">Empathisches Schülerfeedback (wird gedruckt)</label>
                    <textarea
                      value={currentEvaluation.studentFeedback}
                      onChange={(e) => handleTextChange('studentFeedback', e.target.value)}
                      rows={3}
                      className="w-full px-3 py-2 bg-zinc-900 border border-zinc-800 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-zinc-700"
                    />
                  </div>
                </div>
              </div>

              {/* Right Column: Tutoring Plan & JSON Preview */}
              <div className="md:col-span-5 space-y-6">
                {/* 3-Step Tutoring Plan */}
                <div className="bg-gradient-to-br from-violet-650/5 to-indigo-650/5 border border-violet-500/10 rounded-2xl p-5 space-y-5">
                  <h4 className="font-bold text-white text-sm flex items-center gap-2">
                    <HeartHandshake className="w-5 h-5 text-indigo-400" />
                    3-Schritte-Förderplan
                  </h4>

                  <div className="space-y-4">
                    <div className="space-y-1">
                      <span className="text-[10px] font-bold text-indigo-400 uppercase tracking-wider block">1. Empfehlung / Fokus</span>
                      <input
                        type="text"
                        value={currentEvaluation.tutoringPlan.recommendation}
                        onChange={(e) => handleTutoringPlanChange('recommendation', e.target.value)}
                        className="w-full px-3 py-1.5 bg-zinc-950/60 border border-zinc-800 rounded-xl text-xs text-white focus:outline-none"
                      />
                    </div>

                    <div className="space-y-1">
                      <span className="text-[10px] font-bold text-indigo-400 uppercase tracking-wider block">2. Konkrete Übung</span>
                      <textarea
                        value={currentEvaluation.tutoringPlan.exercise}
                        onChange={(e) => handleTutoringPlanChange('exercise', e.target.value)}
                        rows={2}
                        className="w-full px-3 py-1.5 bg-zinc-950/60 border border-zinc-800 rounded-xl text-xs text-white focus:outline-none"
                      />
                    </div>

                    <div className="space-y-1">
                      <span className="text-[10px] font-bold text-indigo-400 uppercase tracking-wider block">3. Langzeittipp</span>
                      <input
                        type="text"
                        value={currentEvaluation.tutoringPlan.longTermTip}
                        onChange={(e) => handleTutoringPlanChange('longTermTip', e.target.value)}
                        className="w-full px-3 py-1.5 bg-zinc-950/60 border border-zinc-800 rounded-xl text-xs text-white focus:outline-none"
                      />
                    </div>
                  </div>
                </div>

                {/* JSON Preview Button / Code */}
                <div className="bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-5 space-y-3 backdrop-blur-xl">
                  <div className="flex justify-between items-center">
                    <span className="text-xs font-bold text-zinc-500 uppercase tracking-wider">Daten-Payload</span>
                    <button
                      onClick={() => setShowJsonPreview(!showJsonPreview)}
                      className="flex items-center gap-1.5 text-xs text-violet-400 hover:text-violet-300 font-semibold"
                    >
                      <Code className="w-3.5 h-3.5" />
                      {showJsonPreview ? 'Verbergen' : 'JSON anzeigen'}
                    </button>
                  </div>

                  {showJsonPreview && (
                    <pre className="text-[10px] text-zinc-400 bg-zinc-950/80 border border-zinc-800/60 p-3 rounded-xl overflow-x-auto font-mono max-h-60 leading-normal">
                      {getStructuredJson()}
                    </pre>
                  )}
                </div>
              </div>
            </div>
          </>
        ) : (
          <div className="bg-zinc-900/40 border border-zinc-800/80 rounded-2xl p-12 text-center text-zinc-500 backdrop-blur-xl">
            Wähle eine Abgabe auf der linken Seite aus, um die KI-Bewertungen zu überprüfen und zu überschreiben.
          </div>
        )}
      </div>
    </div>
  );
}
