import assert from "node:assert/strict";
import test from "node:test";
import { ANTHROPIC_FAST_BETA, doubled, fastLaneFor, withFastMode } from "./fast-mode.ts";

test("Opus 5.5 Messages requests take the Anthropic lane", () => {
	assert.equal(fastLaneFor({ model: "claude-opus-5-5", messages: [] }, "anthropic"), "anthropic");
});

test("Anthropic models without fast mode are left alone", () => {
	assert.equal(fastLaneFor({ model: "claude-fable-5-1", messages: [] }, "anthropic"), undefined);
	assert.equal(fastLaneFor({ model: "claude-haiku-5-5", messages: [] }, "anthropic"), undefined);
});

test("GPT Responses requests take the OpenAI lane", () => {
	assert.equal(fastLaneFor({ model: "gpt-6.1-sol", input: [] }, "openai"), "openai");
});

test("flex providers and unknown payloads are left alone", () => {
	assert.equal(fastLaneFor({ model: "claude-opus-5-5", messages: [] }, "anthropic-flex"), undefined);
	assert.equal(fastLaneFor({ model: "gpt-6.1-sol", input: [] }, "openai-flex"), undefined);
	assert.equal(fastLaneFor({ model: "gemini-3.5-flash", contents: [] }, "google"), undefined);
	assert.equal(fastLaneFor(undefined, "anthropic"), undefined);
});

test("the Anthropic lane adds speed and the fast-mode beta once", () => {
	const once = withFastMode({ model: "claude-opus-5-5", betas: ["interleaved-thinking-2025-05-14"] }, "anthropic");
	assert.equal(once.speed, "fast");
	assert.deepEqual(once.betas, ["interleaved-thinking-2025-05-14", ANTHROPIC_FAST_BETA]);
	assert.deepEqual(withFastMode(once, "anthropic").betas, once.betas);
	assert.deepEqual(withFastMode({ model: "claude-opus-5-5" }, "anthropic").betas, [ANTHROPIC_FAST_BETA]);
});

test("the OpenAI lane requests the priority tier without touching other fields", () => {
	assert.deepEqual(withFastMode({ model: "gpt-6.1-sol", input: [] }, "openai"), { model: "gpt-6.1-sol", input: [], service_tier: "priority" });
});

test("doubled cost doubles every bucket and the total", () => {
	assert.deepEqual(doubled({ input: 1, output: 2, cacheRead: 0.5, cacheWrite: 0.25, total: 3.75 }), {
		input: 2,
		output: 4,
		cacheRead: 1,
		cacheWrite: 0.5,
		total: 7.5,
	});
});
