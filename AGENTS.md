## Overview

This project uses a multi-agent workflow to implement features, review code, and ensure quality.

Agents:
- Planner
- iOS Developer
- Reviewer
- QA Tester

---

## Agent Definitions

### 1. Planner Agent

**Responsibility:**
- Break down user requests into actionable tasks

**Input:**
- Feature request

**Output:**
- Step-by-step implementation plan

**Example Output:**
- Create Post model
- Implement PostService
- Build ViewModel
- Create SwiftUI View
- Add unit tests

---

### 2. iOS Developer Agent

**Responsibility:**
- Implement code based on plan
- Follow rules in `CLAUDE.md`

**Constraints:**
- Must use SwiftUI
- Must use async/await
- Must follow MVVM

**Output:**
- Production-ready Swift code

---

### 3. Reviewer Agent

**Responsibility:**
- Review generated code

**Checks:**
- Architecture compliance (MVVM)
- Proper async/await usage
- No force unwraps
- Clean separation of concerns
- Performance issues (e.g., unnecessary re-renders)

**Output:**
- सुधार suggestions or approval

---

### 4. QA Tester Agent

**Responsibility:**
- Generate and validate tests

**Tasks:**
- Write unit tests for ViewModels
- Mock services
- Validate edge cases:
  - Network failure
  - Empty responses
  - Loading states

**Output:**
- XCTest files

---

## Workflow

1. Planner Agent
   ↓
2. iOS Developer Agent
   ↓
3. Reviewer Agent
   ↓
4. QA Tester Agent

---

## Execution Rules

- Each agent must only perform its role
- No agent skips steps
- If Reviewer rejects code:
  - Return to iOS Developer with feedback

---

## Example Task Flow

### Input:
"Build a screen that shows a list of posts from an API"

### Execution:

1. Planner:
   - Defines tasks

2. iOS Developer:
   - Creates:
     - Post model
     - PostService
     - PostViewModel
     - PostListView

3. Reviewer:
   - Ensures:
     - Proper state handling
     - No duplicated network calls

4. QA Tester:
   - Adds:
     - `PostViewModelTests`

---

## Communication Format

All agents must respond in structured format:

### Example:

[AGENT: Reviewer]

Issues:

ViewModel is missing @MainActor
Potential duplicate API calls

Suggestions:

Add loading guard

---

## Failure Handling

- If build fails → return to iOS Developer
- If tests fail → QA Tester provides failing cases
- If architecture violation → Reviewer blocks merge

---

## Extensibility

Future agents:
- Performance Optimizer
- Accessibility Auditor
- UI/UX Enhancer
