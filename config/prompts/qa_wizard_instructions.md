## Context from Knowledge Base

{{RAG_CONTEXT}}

## Instructions

Based on the context above, generate:
1. A detailed question body that expands on the question title with specific context
2. A comprehensive answer that directly addresses the question
3. Attribution information citing which sources were used

The question body should:
- Be written from the user's perspective (first person)
- Provide specific context about what the user is trying to accomplish
- Be 50-500 characters

The answer should:
- Be comprehensive and directly address the question
- Use markdown formatting (code blocks, lists, bold) where appropriate
- Only include information that can be verified from the provided context
- Be 100-2000 characters

## Response Format

You MUST respond with valid JSON in exactly this format:

```json
{
  "question_body": "The detailed question body written from user perspective...",
  "answer": "The comprehensive answer with markdown formatting...",
  "sources": [
    {
      "type": "Article",
      "id": 123,
      "title": "Source title",
      "excerpt": "Relevant excerpt used..."
    }
  ]
}
```

JSON only, no other text:
