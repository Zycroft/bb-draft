# Prompt Template

| Field | Value |
|-------|-------|
| **Prompt Name** | Prompt Template |
| **Version** | 1.1.0 |
| **Template Reference** | game-specification-v1 |
| **Created** | 2026-01-02 |
| **Status** | Active |

---

## Purpose

This document defines the standard template for all prompt documents in the Baseball Game project. All new prompts should follow this structure to ensure consistency and maintainability.

---

## Template Structure

### Header Metadata (Required)

Every prompt must begin with a level-1 heading and metadata table:

```markdown
# [Prompt Title] Prompt

| Field | Value |
|-------|-------|
| **Prompt Name** | [Descriptive name for the prompt] |
| **Version** | [Major.Minor.Patch - follows semantic versioning] |
| **Template Reference** | game-specification-v1 |
| **Created** | [YYYY-MM-DD] |
| **Status** | [Draft | Active | Deprecated] |
| **Parent Document** | [filename.prompt.md - only for child prompts] |
```

**Field Definitions:**

| Field | Required | Description |
|-------|----------|-------------|
| Prompt Name | Yes | Human-readable name for the prompt |
| Version | Yes | Semantic version (MAJOR.MINOR.PATCH) |
| Template Reference | Yes | Template version used (game-specification-v1) |
| Created | Yes | Initial creation date |
| Status | Yes | Current lifecycle status |
| Parent Document | Conditional | Required for child/subprompts only |

**Status Values:**

| Status | Description |
|--------|-------------|
| Draft | Under development, subject to significant changes |
| Active | Approved and in use |
| Deprecated | No longer in use, kept for reference |

---

### Overview Section (Required)

Provide a concise summary (2-4 sentences) of what this prompt defines and its purpose within the system.

```markdown
---

## Overview

[Brief description of what this prompt covers and why it exists.
Should answer: What is being defined? Why is it needed? How does it fit into the larger system?]
```

---

### Nomenclature Section (Conditional)

Include when the prompt introduces new terms or when clarity is needed. Required for top-level prompts.

```markdown
---

## Nomenclature

| Term | Definition |
|------|------------|
| **[Term]** | [Clear, concise definition] |
```

---

### Content Sections (Required)

The main body of the prompt. Organize into logical sections with clear headings.

**Heading Hierarchy:**
- `##` - Major sections
- `###` - Subsections
- `####` - Sub-subsections (use sparingly)

**Table Formats:**

*Simple Definition Table:*
```markdown
| Term | Description |
|------|-------------|
| **Item** | Description of the item |
```

*Attribute Definition Table:*
```markdown
| Attribute | Type | Description |
|-----------|------|-------------|
| `attributeName` | string | What this attribute represents |
```

*Attribute with Range:*
```markdown
| Attribute | Type | Range | Description |
|-----------|------|-------|-------------|
| `rating` | integer | 20-80 | Skill rating on scouting scale |
```

*Enumeration List:*
```markdown
**[Category] Codes:**
- `CODE1` - Description
- `CODE2` - Description
```

---

### Data Structure Example (Conditional)

Include when defining data models or entities. Use JSON format with realistic example data.

```markdown
---

## Data Structure Example

\`\`\`json
{
  "id": "example-001",
  "name": "Example Entity",
  "attributes": {
    "key": "value"
  }
}
\`\`\`
```

---

### Business Rules Section (Conditional)

Include when there are specific rules, constraints, or logic that must be enforced.

```markdown
---

## Business Rules

1. **Rule Name**: Description of the rule and when it applies
2. **Rule Name**: Description of the rule and when it applies
```

---

### Integration Points Section (Conditional)

Include for prompts that interact with other system components. Describes how this component connects to others.

```markdown
---

## Integration Points

| Component | Integration Description |
|-----------|------------------------|
| **[Component Name]** | How this prompt/system interacts with the component |
```

Or as a bullet list:
```markdown
---

## Integration Points

- **[Component]**: Description of integration
- **[Component]**: Description of integration
```

---

### Related Documents Section (Conditional)

Include when there are parent, child, or sibling prompts that relate to this document.

```markdown
---

## Related Documents

| Document | Relationship | Description |
|----------|--------------|-------------|
| [filename.prompt.md] | Parent | The parent document this extends |
| [filename.prompt.md] | Child | A subprompt that details a specific area |
| [filename.prompt.md] | Related | A sibling prompt with shared concerns |
```

---

### Future Considerations Section (Optional)

Include for items that are out of scope for the current version but should be considered later.

```markdown
---

## Future Considerations

- [Feature or enhancement for future versions]
- [Feature or enhancement for future versions]
```

---

### Change Log Section (Required)

Every prompt must end with a change log. Entries are in reverse chronological order (newest first).

```markdown
---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| X.Y.Z | YYYY-MM-DD | [Author] | [Description of changes] |
| 1.0.0 | YYYY-MM-DD | [Author] | Initial prompt creation |
```

**Versioning Guidelines:**
- **MAJOR (X.0.0)**: Breaking changes, fundamental restructuring
- **MINOR (0.X.0)**: New sections, significant additions, non-breaking enhancements
- **PATCH (0.0.X)**: Clarifications, typo fixes, minor updates

---

## Section Order

Prompts should follow this section order:

1. Header Metadata (Required)
2. Overview (Required)
3. Nomenclature (Conditional - required for parent prompts)
4. Content Sections (Required - varies by prompt)
5. Data Structure Example (Conditional)
6. Business Rules (Conditional)
7. Integration Points (Conditional)
8. Related Documents (Conditional)
9. Future Considerations (Optional)
10. Change Log (Required)

---

## Formatting Guidelines

### General
- Use `---` horizontal rules to separate major sections
- Use **bold** for emphasis on key terms in prose
- Use `code formatting` for attribute names, field names, and values
- Use tables for structured data whenever possible

### Tables
- Always include header row with bold column names
- Left-align text columns
- Use consistent column order across similar tables

### Lists
- Use bullet points (`-`) for unordered lists
- Use numbered lists (`1.`) for sequential or prioritized items
- Use sub-bullets for nested information

### Code Blocks
- Use triple backticks with language identifier
- JSON for data structures
- Markdown for template examples

---

## File Naming Convention

All prompt files should follow this naming pattern:

```
[component-name].prompt.md
```

**Examples:**
- `baseball-game-overview.prompt.md` (parent/overview prompt)
- `player-profile-system.prompt.md` (component prompt)
- `game-simulation-engine.prompt.md` (component prompt)
- `prompt-template.prompt.md` (this template)

**Rules:**
- Use lowercase letters
- Use hyphens to separate words
- End with `.prompt.md`
- Be descriptive but concise

---

## Quick Start Template

Copy the template below for new prompts:

```markdown
# [Component Name] Prompt

| Field | Value |
|-------|-------|
| **Prompt Name** | [Name] |
| **Version** | 1.0.0 |
| **Template Reference** | game-specification-v1 |
| **Created** | [YYYY-MM-DD] |
| **Status** | Draft |
| **Parent Document** | baseball-game-overview.prompt.md |

---

## Overview

[2-4 sentence description of this prompt's purpose]

---

## [First Content Section]

[Content]

---

## [Additional Sections as Needed]

[Content]

---

## Integration Points

- **[Component]**: [Integration description]

---

## Related Documents

| Document | Relationship | Description |
|----------|--------------|-------------|
| baseball-game-overview.prompt.md | Parent | Main game specification |

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | [YYYY-MM-DD] | [Author] | Initial prompt creation |
```

---

## Related Documents

| Document | Relationship | Description |
|----------|--------------|-------------|
| baseball-game-overview.prompt.md | Reference | Main game specification using this template |
| player-profile-system.prompt.md | Reference | Player system prompt using this template |

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.1.0 | 2026-01-02 | Initial | Added Related Documents section |
| 1.0.0 | 2026-01-02 | Initial | Initial template creation with header metadata, section definitions, formatting guidelines, and quick start template |
