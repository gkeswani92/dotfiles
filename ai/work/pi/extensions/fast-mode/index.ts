import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { ANTHROPIC_FAST_MODELS, doubled, fastLaneFor, withFastMode, type Cost } from "./fast-mode.js";

const STATUS_KEY = "fast-mode";

export default function (pi: ExtensionAPI) {
	let enabled = false;
	let anthropicFastSent = false;

	const showStatus = (ctx: ExtensionContext) => ctx.ui.setStatus(STATUS_KEY, enabled ? "⚡ fast (2x price)" : undefined);

	const describeCurrentModel = (ctx: ExtensionContext) => {
		const model = ctx.model;
		if (!model) return "No model is selected yet.";
		const lane = fastLaneFor(
			model.api === "anthropic-messages" ? { model: model.id, messages: [] } : { model: model.id, input: [] },
			model.provider,
		);
		if (lane === "anthropic") return `${model.id} runs in Anthropic fast mode. It counts toward the proxy's $300 daily premium cap.`;
		if (lane === "openai") return `${model.id} runs on OpenAI's priority tier.`;
		return `${model.provider}/${model.id} has no fast lane, so its requests are unchanged.`;
	};

	pi.on("session_start", async (_event, ctx) => {
		enabled = false;
		anthropicFastSent = false;
		showStatus(ctx);
	});

	pi.on("before_provider_request", (event, ctx) => {
		if (!enabled) return undefined;
		const lane = fastLaneFor(event.payload, ctx.model?.provider);
		if (!lane) return undefined;
		if (lane === "anthropic") anthropicFastSent = true;
		return withFastMode(event.payload as Record<string, unknown>, lane);
	});

	pi.on("message_end", (event) => {
		const message = event.message as { role?: string; provider?: string; model?: string; usage?: { cost?: Cost } };
		if (!anthropicFastSent || message.role !== "assistant") return undefined;
		if (!message.model || !ANTHROPIC_FAST_MODELS.has(message.model) || !message.usage?.cost) return undefined;
		anthropicFastSent = false;
		return { message: { ...message, usage: { ...message.usage, cost: doubled(message.usage.cost) } } as typeof event.message };
	});

	pi.registerCommand("fast", {
		description: "Toggle fast mode (2x price): /fast [on|off|status]",
		getArgumentCompletions: (prefix) =>
			["on", "off", "status"].filter((option) => option.startsWith(prefix)).map((option) => ({ value: option, label: option })),
		handler: async (args, ctx) => {
			const choice = args.trim().toLowerCase();
			if (choice === "status") {
				ctx.ui.notify(`Fast mode is ${enabled ? "on" : "off"}. ${describeCurrentModel(ctx)}`, "info");
				return;
			}
			if (choice && choice !== "on" && choice !== "off") {
				ctx.ui.notify("Usage: /fast [on|off|status]", "warning");
				return;
			}
			enabled = choice ? choice === "on" : !enabled;
			showStatus(ctx);
			ctx.ui.notify(enabled ? `Fast mode on for this session. ${describeCurrentModel(ctx)}` : "Fast mode off.", "info");
		},
	});
}
