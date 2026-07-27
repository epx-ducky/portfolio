'use client';

import React, { useState } from 'react';
import { 
  Upload, 
  File, 
  Trash2, 
  CheckCircle, 
  RefreshCw,
  Search,
  Database,
  Layers,
  ArrowRight
} from 'lucide-react';
import { Document } from '../lib/store';

interface WissensdatenbankProps {
  documents: Document[];
  onUpload: (title: string, pageCount: number) => void;
  onDelete: (id: string) => void;
}

export default function Wissensdatenbank({ documents, onUpload, onDelete }: WissensdatenbankProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [uploadingFile, setUploadingFile] = useState<string | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [uploadStep, setUploadStep] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const files = Array.from(e.dataTransfer.files);
    const pdfs = files.filter(f => f.type === 'application/pdf');
    if (pdfs.length > 0) {
      simulateUpload(pdfs[0].name);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      simulateUpload(e.target.files[0].name);
    }
  };

  const simulateUpload = (filename: string) => {
    setUploadingFile(filename);
    setUploadProgress(0);
    setUploadStep('Lese PDF-Seiten...');

    // Simulate different parsing/embedding steps
    const interval = setInterval(() => {
      setUploadProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setTimeout(() => {
            // Mock dynamic page count
            const randomPages = Math.floor(Math.random() * 20) + 5;
            onUpload(filename, randomPages);
            setUploadingFile(null);
          }, 600);
          return 100;
        }

        const nextProgress = prev + 5;
        if (nextProgress === 30) {
          setUploadStep('Dekomponiere in Text-Chunks...');
        } else if (nextProgress === 60) {
          setUploadStep('Generiere Vektor-Embeddings...');
        } else if (nextProgress === 85) {
          setUploadStep('Speichere in Supabase (pgvector)...');
        }
        return nextProgress;
      });
    }, 150);
  };

  const filteredDocs = documents.filter(doc => 
    doc.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Module Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white">Wissensdatenbank</h2>
          <p className="text-zinc-400 text-sm mt-1">
            Unterrichtsmaterialien hochladen, um sie als RAG-Kontext (die absolute Wahrheit) für die Korrekturen zu nutzen.
          </p>
        </div>
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-zinc-800 border border-zinc-700 text-xs text-zinc-300 font-medium">
          <Database className="w-4 h-4 text-violet-400" />
          <span>pgvector aktiv</span>
        </div>
      </div>

      {/* Upload Area */}
      <div 
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        className={`border-2 border-dashed rounded-2xl p-8 flex flex-col items-center justify-center text-center transition-all duration-300 ${
          isDragging 
            ? 'border-violet-500 bg-violet-600/5 shadow-inner' 
            : 'border-zinc-800 bg-zinc-900/20 hover:border-zinc-700'
        }`}
      >
        {uploadingFile ? (
          <div className="w-full max-w-md space-y-4">
            <div className="flex justify-between text-sm text-zinc-300">
              <span className="font-medium truncate max-w-xs">{uploadingFile}</span>
              <span className="text-zinc-500 font-semibold">{uploadProgress}%</span>
            </div>
            
            {/* Progress bar */}
            <div className="w-full bg-zinc-800 rounded-full h-2.5 overflow-hidden">
              <div 
                className="bg-gradient-to-r from-violet-500 to-indigo-500 h-2.5 rounded-full transition-all duration-200"
                style={{ width: `${uploadProgress}%` }}
              ></div>
            </div>

            <div className="flex items-center justify-center gap-2 text-xs text-violet-400">
              <RefreshCw className="w-3.5 h-3.5 animate-spin" />
              <span>{uploadStep}</span>
            </div>
          </div>
        ) : (
          <>
            <div className="w-12 h-12 rounded-xl bg-zinc-900 border border-zinc-800 flex items-center justify-center mb-4">
              <Upload className="w-6 h-6 text-zinc-400" />
            </div>
            <p className="text-sm font-semibold text-white">Unterrichtsskript oder Buchkapitel hochladen</p>
            <p className="text-xs text-zinc-500 mt-1.5 max-w-sm">
              Ziehe eine PDF-Datei hierher oder klicke zum Auswählen. Maximal 150 Seiten für optimalen RAG-Kontext.
            </p>
            <label className="mt-4 px-4 py-2 bg-zinc-800 hover:bg-zinc-700 border border-zinc-700 rounded-xl text-xs font-semibold text-white cursor-pointer transition-colors shadow-sm">
              Datei auswählen
              <input 
                type="file" 
                accept=".pdf" 
                className="hidden" 
                onChange={handleFileChange}
              />
            </label>
          </>
        )}
      </div>

      {/* Library Table */}
      <div className="bg-zinc-900/40 border border-zinc-800/80 rounded-2xl overflow-hidden backdrop-blur-xl">
        <div className="p-5 border-b border-zinc-800 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <h3 className="font-bold text-white text-base flex items-center gap-2">
            <Layers className="w-5 h-5 text-indigo-400" />
            Dokumentenbibliothek
            <span className="text-xs font-semibold bg-zinc-800 px-2 py-0.5 rounded-full text-zinc-400">
              {documents.length}
            </span>
          </h3>
          <div className="relative">
            <Search className="w-4 h-4 text-zinc-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Dokument suchen..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 pr-4 py-1.5 bg-zinc-900 border border-zinc-800 rounded-xl text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-zinc-700 w-full sm:w-64"
            />
          </div>
        </div>

        {filteredDocs.length === 0 ? (
          <div className="py-12 text-center text-zinc-500 text-sm">
            Keine Dokumente gefunden. Lade dein erstes PDF hoch.
          </div>
        ) : (
          <div className="divide-y divide-zinc-800/60">
            {filteredDocs.map((doc) => (
              <div key={doc.id} className="p-4 flex items-center justify-between hover:bg-zinc-800/10 transition-colors">
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-10 h-10 rounded-lg bg-red-500/10 border border-red-500/20 flex items-center justify-center">
                    <File className="w-5 h-5 text-red-400" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-white truncate">{doc.title}</p>
                    <div className="flex items-center gap-2 text-xs text-zinc-500 mt-1">
                      <span>{doc.pageCount} Seiten</span>
                      <span>•</span>
                      <span>Hochgeladen am {new Date(doc.createdAt).toLocaleDateString('de-DE')}</span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-1.5 text-xs text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-full border border-emerald-500/20">
                    <CheckCircle className="w-3.5 h-3.5" />
                    <span>Embedded</span>
                  </div>
                  <button 
                    onClick={() => onDelete(doc.id)}
                    className="p-2 text-zinc-500 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Info Card / Workflow explanation */}
      <div className="bg-gradient-to-r from-violet-600/5 to-indigo-600/5 border border-indigo-500/10 rounded-2xl p-5 flex gap-4">
        <div className="w-8 h-8 rounded-lg bg-indigo-500/15 flex items-center justify-center flex-shrink-0">
          <Database className="w-4.5 h-4.5 text-indigo-400" />
        </div>
        <div>
          <h4 className="font-semibold text-white text-sm">Wie funktioniert der RAG-Abgleich?</h4>
          <p className="text-xs text-zinc-400 mt-1 leading-relaxed">
            Deine PDFs werden lokal zerlegt und per Supabase Edge Function in Vektor-Embeddings umgewandelt. 
            Bei der Klausurerstellung und Korrektur vergleicht das LLM die Fragen und Schülerantworten direkt mit diesen semantischen Daten. 
            Dadurch korrigiert die KI ausschließlich auf Basis deines Unterrichtsstoffes und beugt Halluzinationen vor.
          </p>
        </div>
      </div>
    </div>
  );
}
