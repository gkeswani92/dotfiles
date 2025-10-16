You are helping create a new Claude Code slash command.

## Your Task

1. **Ask the user** what they want the new command to do. Get a clear understanding of:
   - The command name (should be kebab-case, e.g., "analyze-logs", "fix-tests")
   - What the command should accomplish
   - Any specific tools or workflows it should use
   - Any inputs it should expect from the user

2. **Design the command** with a clear structure:
   - Opening description of what the command does
   - Step-by-step instructions for the AI
   - Any important notes or constraints
   - Examples if helpful

3. **Create the command file** at `/Users/gaurav/dotfiles/claude_configuration/commands/{command-name}.md`
   - Use markdown format
   - Be clear and specific in instructions
   - Include any necessary context

4. **After saving**, remind the user to:
   ```bash
   source ~/.zshrc
   ```
   This will make the new command available in the current session.

## Command Template

Use this general structure:

```markdown
[Brief description of what this command does]

## Your Task

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Notes
- [Important considerations]
- [Constraints or requirements]

## Example Usage
[If helpful, show how the user would invoke this]
```

## Tips for Good Commands

- Be specific about what tools to use (e.g., "use mcp__slack-mcp__slack_search", "use the Bash tool")
- Include clear success criteria
- Specify what to ask the user vs. what to infer
- Keep it focused - one clear purpose per command
- Think about reusability across different contexts
