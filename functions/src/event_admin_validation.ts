import { HttpsError } from "firebase-functions/v2/https";

export type Data = Record<string, unknown>;
export function invalid(name: string): never {
  throw new HttpsError("invalid-argument", `${name} が不正です。`);
}
export function object(value: unknown): Data {
  if (!value || typeof value !== "object" || Array.isArray(value)) invalid("リクエスト");
  return value as Data;
}
export function id(value: unknown): string {
  if (typeof value !== "string" || !value || value.length > 128 || value.includes("/") || value === "." || value === "..") {
    invalid("ID");
  }
  return value;
}
export function text(value: unknown, max = 10000, required = true): string {
  if (typeof value !== "string" || value.length > max || (required && !value.trim())) invalid("テキスト");
  return value.trim();
}
export function integer(value: unknown, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) invalid("数値");
  return value;
}
export function locale(value: unknown, required = true): Data {
  const data = object(value);
  return { ja: text(data.ja, 10000, required), en: text(data.en, 10000, false) };
}
export function strings(value: unknown, max: number, parse: (value: unknown) => string): string[] {
  if (!Array.isArray(value) || value.length > max) invalid("リスト");
  return value.map(parse);
}

// Shared allowlists for editing and promotion: runtime state and revealed
// answers must never be copied into a fresh production event/question.
export function eventDefinition(input: Data) {
  return {
    title: locale(input.title), capacity: integer(input.capacity, 3, 80),
    sponsorIds: strings(input.sponsorIds ?? [], 100, id),
    teamNamePool: strings(input.teamNamePool ?? [], 100, (value) => text(value, 80)),
  };
}
export function questionDefinition(question: Data, answer: Data) {
  if (!Array.isArray(question.options) || question.options.length < 2 || question.options.length > 4) invalid("選択肢");
  return {
    content: {
      sponsorId: id(question.sponsorId), order: integer(question.order, 0, 10000), title: locale(question.title),
      options: question.options.map((value) => locale(value)), durationSeconds: integer(question.durationSeconds, 1, 1800),
    },
    secret: {
      correctOptionIndex: integer(answer.correctOptionIndex, 0, question.options.length - 1),
      explanation: locale(answer.explanation, false),
    },
  };
}
