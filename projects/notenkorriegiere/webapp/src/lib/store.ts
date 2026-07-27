'use client';

// A lightweight LocalStorage-backed state manager for the EdTech Grading & Feedback app.
// Allows fully interactive prototyping. In a production environment, these actions would call Supabase APIs.

export interface Class {
  id: string;
  name: string;
  subject: string;
}

export interface Document {
  id: string;
  title: string;
  pageCount: number;
  createdAt: string;
}

export interface Question {
  id: string;
  questionText: string;
  maxPoints: number;
  expectedAnswer: string;
}

export interface Exam {
  id: string;
  title: string;
  description: string;
  classId: string;
  status: 'draft' | 'published' | 'graded';
  questions: Question[];
  createdAt: string;
}

export interface Submission {
  id: string;
  examId: string;
  studentIdentifier: string; // anonymized, e.g. "Schüler A"
  totalScore: number;
  createdAt: string;
}

export interface Evaluation {
  id: string;
  submissionId: string;
  questionId: string;
  studentAnswerText: string;
  awardedPoints: number;
  teacherAnalysis: string;
  studentFeedback: string;
  tutoringPlan: {
    recommendation: string;
    exercise: string;
    longTermTip: string;
  };
  isOverridden: boolean;
}

// Initial mock data
const INITIAL_CLASSES: Class[] = [
  { id: 'c1', name: '10a', subject: 'Mathematik' },
  { id: 'c2', name: '12b', subject: 'Physik' },
];

const INITIAL_DOCUMENTS: Document[] = [
  { id: 'd1', title: 'Skript_Lineare_Funktionen.pdf', pageCount: 12, createdAt: '2026-06-15T10:00:00Z' },
  { id: 'd2', title: 'Grundlagen_Analytische_Geometrie.pdf', pageCount: 24, createdAt: '2026-06-20T14:30:00Z' },
];

const INITIAL_EXAMS: Exam[] = [
  {
    id: 'e1',
    title: '1. Klassenarbeit: Lineare Funktionen',
    description: 'Themen: Steigung, Achsenabschnitt, Nullstellen und Schnittpunkte zweier Geraden.',
    classId: 'c1',
    status: 'graded',
    createdAt: '2026-06-25T08:00:00Z',
    questions: [
      {
        id: 'q1',
        questionText: 'Bestimme die Funktionsgleichung der Geraden g, die durch die Punkte A(1|2) und B(3|6) verläuft.',
        maxPoints: 4,
        expectedAnswer: 'Steigung m = (6 - 2) / (3 - 1) = 4 / 2 = 2. Einsetzen von A(1|2): 2 = 2*1 + n => n = 0. Funktionsgleichung: y = 2x.',
      },
      {
        id: 'q2',
        questionText: 'Erkläre den Unterschied zwischen einer steigenden und einer fallenden linearen Funktion anhand des Steigungsfaktors m.',
        maxPoints: 2,
        expectedAnswer: 'Bei einer steigenden linearen Funktion ist m > 0 (die Gerade verläuft von links unten nach rechts oben). Bei einer fallenden linearen Funktion ist m < 0 (die Gerade verläuft von links oben nach rechts unten).',
      },
      {
        id: 'q3',
        questionText: 'Berechne den Schnittpunkt der beiden Geraden f(x) = 2x - 3 und g(x) = -x + 6.',
        maxPoints: 4,
        expectedAnswer: 'Gleichsetzen: 2x - 3 = -x + 6 => 3x = 9 => x = 3. Einsetzen in f(x): f(3) = 2*3 - 3 = 3. Schnittpunkt S(3|3).',
      }
    ]
  }
];

const INITIAL_SUBMISSIONS: Submission[] = [
  { id: 's1', examId: 'e1', studentIdentifier: 'Schüler A (Code: X9B3)', totalScore: 8, createdAt: '2026-07-01T09:00:00Z' },
  { id: 's2', examId: 'e1', studentIdentifier: 'Schüler B (Code: H4Y1)', totalScore: 6, createdAt: '2026-07-01T09:05:00Z' }
];

const INITIAL_EVALUATIONS: Evaluation[] = [
  // Schüler A
  {
    id: 'ev1',
    submissionId: 's1',
    questionId: 'q1',
    studentAnswerText: 'm = (6-2)/(3-1) = 4/2 = 2. Dann y = 2x + c. 2 = 2*1 + c => c = 0. Also y = 2x.',
    awardedPoints: 4,
    teacherAnalysis: 'Der Schüler hat die Steigung m korrekt berechnet und c (den Achsenabschnitt) korrekt bestimmt. Der Rechenweg ist sauber dokumentiert und die finale Gleichung ist richtig.',
    studentFeedback: 'Sehr gut! Du hast beide Parameter der Geradengleichung Schritt für Schritt sauber hergeleitet und das richtige Ergebnis erzielt.',
    tutoringPlan: {
      recommendation: 'Festige dein Wissen durch das Aufstellen von Geradengleichungen in Sachzusammenhängen.',
      exercise: 'Bestimme die Gleichung einer Geraden, die die Kostenentwicklung beschreibt (z. B. Grundgebühr 5€, 2€ pro km).',
      longTermTip: 'Achte darauf, bei Prüfungen immer die Einheiten anzugeben, falls Sachaufgaben gelöst werden.'
    },
    isOverridden: false
  },
  {
    id: 'ev2',
    submissionId: 's1',
    questionId: 'q2',
    studentAnswerText: 'Wenn m positiv ist, steigt die Gerade. Wenn m negativ ist, fällt sie.',
    awardedPoints: 2,
    teacherAnalysis: 'Die Erklärung ist kurz, trifft aber den Kern der Sache. Der Steigungsfaktor m wurde richtig mit "positiv" und "negativ" verknüpft.',
    studentFeedback: 'Richtig erklärt. Versuche beim nächsten Mal noch mathematische Begriffe wie "m > 0" und "m < 0" zu nutzen.',
    tutoringPlan: {
      recommendation: 'Ergänze deine Formulierungen mit präziser mathematischer Notation.',
      exercise: 'Schreibe den Satz noch einmal auf und nutze dabei die Zeichen ">" und "<".',
      longTermTip: 'Präzise Notation spart Schreibarbeit und bringt in Klausuren die volle Punktzahl.'
    },
    isOverridden: false
  },
  {
    id: 'ev3',
    submissionId: 's1',
    questionId: 'q3',
    studentAnswerText: '2x - 3 = -x + 6 => 3x = 9 => x = 3. Schnittpunkt bei x = 3.',
    awardedPoints: 2,
    teacherAnalysis: 'Der Schüler hat das Gleichsetzungsverfahren richtig angewendet und die x-Koordinate des Schnittpunkts korrekt berechnet. Allerdings wurde vergessen, die y-Koordinate zu berechnen und den Schnittpunkt als Punkt S(x|y) anzugeben.',
    studentFeedback: 'Guter Ansatz! Die x-Koordinate stimmt. Vergiss aber nicht, dass ein Schnittpunkt immer zwei Koordinaten (x und y) hat. Setze x in eine der Gleichungen ein, um y zu bestimmen.',
    tutoringPlan: {
      recommendation: 'Wiederhole das vollständige Berechnen von Schnittpunkten.',
      exercise: 'Berechne den Schnittpunkt von f(x) = 3x - 1 und g(x) = x + 3 vollständig.',
      longTermTip: 'Erstelle am Ende einer Aufgabe eine kurze Checkliste: "Habe ich alle Teile der Frage beantwortet (z. B. Punkt = x und y)?"'
    },
    isOverridden: false
  },
  // Schüler B
  {
    id: 'ev4',
    submissionId: 's2',
    questionId: 'q1',
    studentAnswerText: 'Steigung ist m = 6-2 / 3-1 = 2. Die Gleichung ist y = 2x + 1.',
    awardedPoints: 2,
    teacherAnalysis: 'Steigung m = 2 ist korrekt berechnet. Beim Einsetzen eines Punktes zur Bestimmung des Achsenabschnitts n (oder c) ist dem Schüler jedoch ein Fehler unterlaufen (y = 2x + 1 statt y = 2x). Dadurch ist das Endergebnis falsch.',
    studentFeedback: 'Die Steigung m hast du richtig berechnet. Beim Bestimmen des Achsenabschnitts hast du dich leider verrechnet. Wenn du A(1|2) einsetzt: 2 = 2*(1) + n, muss n = 0 sein.',
    tutoringPlan: {
      recommendation: 'Übe das Einsetzen von Punkten in die allgemeine Form y = mx + n.',
      exercise: 'Gegeben m = 3 und Punkt P(2|5). Berechne n.',
      longTermTip: 'Mache immer die Punktprobe: Setze die Koordinaten deines Punktes in deine fertige Gleichung ein, um zu prüfen, ob sie stimmt.'
    },
    isOverridden: false
  },
  {
    id: 'ev5',
    submissionId: 's2',
    questionId: 'q2',
    studentAnswerText: 'm gibt an wie steil es ist. Wenn m groß ist geht es hoch, bei minus runter.',
    awardedPoints: 1,
    teacherAnalysis: 'Umgangssprachlich korrekt, aber unpräzise. "Wenn m groß ist geht es hoch" ist falsch (m = 0.5 steigt auch, m = -5 fällt sehr steil). Der Bezug zum Vorzeichen von m ist im Ansatz vorhanden ("bei minus runter").',
    studentFeedback: 'Im Ansatz verstanden! Wichtig ist hier das Vorzeichen: Ist m positiv (größer als 0), steigt die Gerade. Ist m negativ (kleiner als 0), fällt sie. Die absolute Größe von m bestimmt nur die Steilheit.',
    tutoringPlan: {
      recommendation: 'Schau dir den Einfluss des Vorzeichens im Vergleich zur Steilheit an.',
      exercise: 'Skizziere grob die Geraden y = 0.5x und y = -3x, um den Unterschied zu sehen.',
      longTermTip: 'Nutze Fachbegriffe wie "positiv/negativ" statt "groß/minus".'
    },
    isOverridden: false
  },
  {
    id: 'ev6',
    submissionId: 's2',
    questionId: 'q3',
    studentAnswerText: '2x - 3 = -x + 6. Ich weiß nicht wie man das auflöst.',
    awardedPoints: 3,
    teacherAnalysis: 'Der Schüler hat den richtigen Ansatz gewählt (Gleichsetzen der Terme), konnte die lineare Gleichung danach aber nicht auflösen. 3 von 4 Punkten abgezogen für fehlende Äquivalenzumformungen und fehlendes Endergebnis.',
    studentFeedback: 'Super, dass du die beiden Funktionen gleichgesetzt hast! Das ist genau der richtige erste Schritt. Um nach x aufzulösen, bringst du zuerst alle x auf eine Seite (z. B. "+ x") und die Zahlen auf die andere.',
    tutoringPlan: {
      recommendation: 'Wiederhole Äquivalenzumformungen bei linearen Gleichungen.',
      exercise: 'Löse die Gleichung 3x - 5 = 10 nach x auf.',
      longTermTip: 'Bringe immer systematisch Variable auf die eine Seite, Zahlen auf die andere Seite der Gleichung.'
    },
    isOverridden: false
  }
];

export function getInitialState() {
  if (typeof window === 'undefined') {
    return {
      classes: INITIAL_CLASSES,
      documents: INITIAL_DOCUMENTS,
      exams: INITIAL_EXAMS,
      submissions: INITIAL_SUBMISSIONS,
      evaluations: INITIAL_EVALUATIONS
    };
  }

  const classes = localStorage.getItem('edtech_classes');
  const documents = localStorage.getItem('edtech_documents');
  const exams = localStorage.getItem('edtech_exams');
  const submissions = localStorage.getItem('edtech_submissions');
  const evaluations = localStorage.getItem('edtech_evaluations');

  if (!classes || !documents || !exams || !submissions || !evaluations) {
    localStorage.setItem('edtech_classes', JSON.stringify(INITIAL_CLASSES));
    localStorage.setItem('edtech_documents', JSON.stringify(INITIAL_DOCUMENTS));
    localStorage.setItem('edtech_exams', JSON.stringify(INITIAL_EXAMS));
    localStorage.setItem('edtech_submissions', JSON.stringify(INITIAL_SUBMISSIONS));
    localStorage.setItem('edtech_evaluations', JSON.stringify(INITIAL_EVALUATIONS));

    return {
      classes: INITIAL_CLASSES,
      documents: INITIAL_DOCUMENTS,
      exams: INITIAL_EXAMS,
      submissions: INITIAL_SUBMISSIONS,
      evaluations: INITIAL_EVALUATIONS
    };
  }

  return {
    classes: JSON.parse(classes),
    documents: JSON.parse(documents),
    exams: JSON.parse(exams),
    submissions: JSON.parse(submissions),
    evaluations: JSON.parse(evaluations)
  };
}

export function saveState(state: {
  classes: Class[];
  documents: Document[];
  exams: Exam[];
  submissions: Submission[];
  evaluations: Evaluation[];
}) {
  if (typeof window === 'undefined') return;
  localStorage.setItem('edtech_classes', JSON.stringify(state.classes));
  localStorage.setItem('edtech_documents', JSON.stringify(state.documents));
  localStorage.setItem('edtech_exams', JSON.stringify(state.exams));
  localStorage.setItem('edtech_submissions', JSON.stringify(state.submissions));
  localStorage.setItem('edtech_evaluations', JSON.stringify(state.evaluations));
}
