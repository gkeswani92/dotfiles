export const ANTHROPIC_FAST_MODELS = new Set(["claude-opus-5-5"]);
export const ANTHROPIC_FAST_BETA = "fast-mode-2026-02-01";

export type FastLane = "anthropic" | "openai";

type Payload = Record<string, unknown>;

export function fastLaneFor(payload: unknown, provider: string | undefined): FastLane | undefined {
	if (!payload || typeof payload !== "object") return undefined;
	if (provider?.includes("flex")) return undefined;
	const { model } = payload as Payload;
	if (typeof model !== "string") return undefined;
	if (ANTHROPIC_FAST_MODELS.has(model) && "messages" in payload) return "anthropic";
	if (model.startsWith("gpt-") && "input" in payload) return "openai";
	return undefined;
}

export function withFastMode(payload: Payload, lane: FastLane): Payload {
	if (lane === "openai") return { ...payload, service_tier: "priority" };
	const betas = Array.isArray(payload.betas) ? payload.betas : [];
	return {
		...payload,
		speed: "fast",
		betas: betas.includes(ANTHROPIC_FAST_BETA) ? betas : [...betas, ANTHROPIC_FAST_BETA],
	};
}

export interface Cost {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	total: number;
}

export function doubled(cost: Cost): Cost {
	return {
		...cost,
		input: cost.input * 2,
		output: cost.output * 2,
		cacheRead: cost.cacheRead * 2,
		cacheWrite: cost.cacheWrite * 2,
		total: cost.total * 2,
	};
}
