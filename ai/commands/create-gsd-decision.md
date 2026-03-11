Generate a GSD (Get Stuff Done) decision log from a Slack thread or pasted text.

## Your Task

Create a structured decision document following Shopify's GSD decision format, which includes:
- Background context explaining the problem/question
- Multiple options that were considered
- Clear indication of which option was Accepted vs Rejected
- Pros and Cons for each option
- Metadata (date, participants, links)

## Input Handling

1. **Determine the input type** by asking the user:
   - "Do you have a Slack thread URL or text to paste?"

2. **If Slack thread URL provided**:
   - Use `mcp__slack-mcp__get_messages` with action "thread" to fetch the conversation
   - Extract the channel ID and thread timestamp from the URL
   - Slack URLs look like: `https://shopify.slack.com/archives/CHANNEL_ID/pTIMESTAMP`

3. **If text is pasted**:
   - Parse the provided text directly

## Decision Extraction Process

1. **Extract Background Context**:
   - Identify the core question or problem being decided
   - Look for explanations of why this decision is needed
   - Synthesize from the discussion if not explicitly stated
   - **If context is unclear, ask the user**: "Can you provide more background on what problem this decision addresses?"

2. **Identify Options**:
   - Look for distinct approaches or solutions discussed
   - Each option should have a clear, descriptive title
   - Options are often numbered or labeled in discussions

3. **Determine Accepted vs Rejected**:
   - Look for phrases like: "we decided", "going with", "let's do", "accepted", "rejected", "not going with", "ruled out"
   - Look for emoji reactions (checkmarks, x marks) if visible
   - **If unclear, ask the user**: "Which option was selected as the final decision?"

4. **Synthesize Pros and Cons**:
   - Extract explicit pros/cons if stated
   - Synthesize from discussion points (arguments for/against each option)
   - If not enough information for a particular option, just describe what the option entails without forcing pros/cons
   - Label as "Upsides" and "Downsides" OR "Pros" and "Cons" (be consistent)

5. **Extract Metadata**:
   - **Date**: When the decision was made (from thread timestamp or ask user)
   - **Participants**: Who was involved in the discussion (from Slack usernames or ask user)
   - **Related Links**: PRs, docs, or other resources mentioned in the discussion

## Output Format

Generate the decision in this markdown format:

```markdown
# [Decision Title]

**Date**: [YYYY-MM-DD]
**Participants**: [Names or handles]
**Related Links**: [If any]

## Background

[2-4 paragraphs explaining the problem/question and why a decision is needed]

## Options

### [Option 1 Title]
**[Accepted/Rejected]**

[Description of the option]

**Pros**
- [Pro 1]
- [Pro 2]

**Cons**
- [Con 1]
- [Con 2]

### [Option 2 Title]
**[Accepted/Rejected]**

[Description of the option]

**Pros**
- [Pro 1]
- [Pro 2]

**Cons**
- [Con 1]
- [Con 2]

[Additional options as needed...]
```

## Output Actions

1. **Display the raw markdown** in the response so the user can review it

2. **Copy to clipboard** using:
   ```bash
   echo 'MARKDOWN_CONTENT' | pbcopy
   ```

3. **Save to file**:
   - Directory: `/Users/gaurav/Documents/notes/Shopify/Shopify/GSD Decisions`
   - Create directory if it doesn't exist: `mkdir -p "/Users/gaurav/Documents/notes/Shopify/Shopify/GSD Decisions"`
   - Filename: `[YYYY-MM-DD] [Decision Title].md` (sanitize title for filename)
   - Confirm the save location to the user

## Notes

- Keep the accepted option near the top or clearly marked
- Be concise but thorough - capture the key reasoning
- If the discussion is lengthy, focus on the substantive arguments not the back-and-forth
- Preserve technical accuracy - don't paraphrase technical terms incorrectly
- If multiple decisions were made in one thread, ask the user which one to document or offer to create separate documents

## Example Invocation

User: `/create-gsd-decision`
Assistant: "Do you have a Slack thread URL or text to paste?"
User: [provides input]
Assistant: [processes and generates decision document]
