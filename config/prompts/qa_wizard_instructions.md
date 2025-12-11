## Context from Knowledge Base

{{RAG_CONTEXT}}

## Instructions

Based on the context above, generate:
1. A detailed question body that expands on the question title with specific context
2. A comprehensive answer that directly addresses the question with inline citations
3. Attribution information citing which sources were used

The question body should:
- Be written from the user's perspective (first person)
- Provide specific context about what the user is trying to accomplish
- Be 50-500 characters

The answer should:
- Be comprehensive and directly address the question
- Use markdown formatting (code blocks, lists, bold) where appropriate
- **IMPORTANT: Cite sources inline** using the format `[1]`, `[2]`, etc. Place citations immediately after the relevant statement
- Only include information that can be verified from the provided context
- Be 100-2000 characters

Example of good inline citations:
"You can reset your password by clicking the 'Forgot Password' link [1]. Make sure to check your spam folder if you don't receive the email within 5 minutes [2]."

## Response Format

You MUST respond with valid JSON in exactly this format:

```json
{
  "question_body": "The detailed question body written from user perspective...",
  "answer": "The comprehensive answer with inline citations like [1] and [2]...",
  "sources": [
    {
      "number": 1,
      "type": "Article",
      "id": 123,
      "title": "Source title",
      "excerpt": "The specific excerpt from this source that was used..."
    }
  ]
}
```

Only include sources that you actually referenced in your answer. The excerpt should be the specific text from the source that supports your answer. The "number" field must match the citation number used in the answer.

JSON only, no other text:
