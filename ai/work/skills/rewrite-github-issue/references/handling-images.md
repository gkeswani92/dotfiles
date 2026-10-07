# Handling Images in Issues

Images in GitHub issues often contain critical context—screenshots of UIs, error messages, settings panels, comparison views. This guide covers how to analyze and document them.

## Workflow

### Step 1: Identify Images

Scan the issue body and comments for:
- Markdown: `![alt text](URL)`
- HTML: `<img src="URL" />`
- Common hosts:
  - `storage.googleapis.com/shopify-ihub-github-archiver/`
  - `user-images.githubusercontent.com/`
  - `files.slack.com/`

### Step 2: Download Images

```bash
# Single image (public)
curl -sO "https://storage.googleapis.com/shopify-ihub-github-archiver/<image-hash>.png"

# Multiple images (public)
cd ~/Downloads && \
curl -sO "URL1" && \
curl -sO "URL2" && \
curl -sO "URL3"
```

**GitHub-hosted images (require authentication):**

```bash
# Set the image URL you extracted
IMAGE_URL="https://github.com/..." # Replace with actual URL

# Use curl with GitHub auth token
curl -L -H "Authorization: token $(gh auth token)" "$IMAGE_URL" -o image.png
```

Note: The `-L` flag follows redirects, which GitHub often uses for image delivery.

### Step 3: Analyze Each Image

Use the Read tool to view downloaded images. Look for:

| Image Type | Key Information to Extract |
|------------|---------------------------|
| UI Screenshot | Current behavior, problematic elements, user flow |
| Settings Panel | Configuration state, toggles, options selected |
| Error Message | Exact error text, error codes, stack traces |
| Comparison | What changed, expected vs actual behavior |
| Admin/Dashboard | Feature flags, merchant settings, system state |
| Mobile Screen | Platform-specific behavior, responsive issues |

### Step 4: Document in Rewrite

Include images with clear descriptions:

```markdown
### Screenshots

**[Descriptive Title for Image 1]**
[1-2 sentence description of what the image shows and why it's relevant]

![Alt text describing the image](original-image-URL)

**[Descriptive Title for Image 2]**
[Description of what this demonstrates]

![Alt text](original-image-URL)
```

**Example:**

```markdown
### Screenshots

**PDP - Current State (Problem)**
Shows "Shipping calculated at checkout" with no delivery speed indicator:

![PDP showing unhelpful shipping message](URL1)

**Merchant Settings**
The merchant has "Estimated delivery dates" set to Manual:

![Merchant delivery settings](URL2)

**Checkout - Shows Useful Info**
Checkout displays actual delivery window that PDP lacks:

![Checkout showing delivery dates](URL3)
```

## Best Practices

| Do | Don't |
|----|-------|
| Keep original URLs | Re-upload images |
| Add descriptive titles | Use "Screenshot 1" |
| Explain what to look for | Assume it's obvious |
| Group related images logically | Scatter randomly |
| Note image limitations | Ignore quality issues |

## Handling Inaccessible Images

**Behind authentication (e.g., Slack files):**
- Ask user if they can provide the images
- Note: "Screenshots exist but couldn't be accessed"
- Describe what the image supposedly shows based on context

**Broken/404:**
- Remove broken image references
- Add note if critical: "Note: Original screenshot no longer available"

## Checklist

- [ ] Identified all images in the issue thread
- [ ] Downloaded images that need analysis
- [ ] Viewed each image to understand content
- [ ] Added descriptive titles and context
- [ ] Preserved original image URLs
- [ ] Grouped related images logically
- [ ] Noted any inaccessible or broken images
