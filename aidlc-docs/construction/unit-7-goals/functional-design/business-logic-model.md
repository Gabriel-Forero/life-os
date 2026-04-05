# Unit 7 — Goals: Business Logic Model

## Flow 1: Create Goal

```
User submits GoalInput
  → validateGoalName(input.name)       [1–100 chars]
  → validateGoalDescription(input.description)  [nullable, max 500]
  → validateGoalCategory(input.category)        [enum check]
  → validateGoalTargetDate(input.targetDate)    [nullable, must be future]
  → GoalsDao.insertGoal(GoalsCompanion)
  → Return Success(goalId)
```

---

## Flow 2: Add Sub-Goals (with weight validation)

```
User submits SubGoalInput for goalId
  → validateSubGoalName(input.name)            [1–100 chars]
  → validateSubGoalDescription(input.description) [nullable, max 200]
  → validateSubGoalWeight(input.weight)        [0 < w <= 1.0]
  → GoalsDao.getSubGoalsForGoal(goalId)
  → existingWeightSum = sum of all current weights
  → newTotal = existingWeightSum + input.weight
  → if abs(newTotal - 1.0) > 0.001 → return ValidationFailure
  → GoalsDao.insertSubGoal(SubGoalsCompanion)
  → Return Success(subGoalId)
```

---

## Flow 3: Weighted Progress Calculation

```
calculateWeightedProgress(goalId):
  → GoalsDao.getSubGoalsForGoal(goalId)
  → if subGoals.isEmpty → return 0
  → progress = sum(s.weight × s.progress for s in subGoals)
  → clamp(progress.round(), 0, 100)
```

Called after any sub-goal progress update. Result is persisted to life_goals.progress.

---

## Flow 4: Milestone Tracking

```
User submits MilestoneInput for goalId
  → validateMilestoneName(input.name)          [1–100 chars]
  → validateMilestoneTargetProgress(input.targetProgress) [0–100]
  → validateMilestoneTargetDate(input.targetDate) [nullable, not past]
  → GoalsDao.insertMilestone(GoalMilestonesCompanion)
  → Return Success(milestoneId)

completeMilestone(milestoneId):
  → GoalsDao.getMilestone(milestoneId)
  → if not found → NotFoundFailure
  → if already completed → ValidationFailure
  → GoalsDao.updateMilestone(isCompleted=true, completedAt=now)
  → Return Success(null)
```

---

## Flow 5: Auto-Progress from EventBus

### 5a. HabitCheckedInEvent

```
onHabitCheckedIn(event):
  → GoalsDao.getSubGoalsLinkedTo('habits', event.habitId)
  → for each subGoal where isOverridden = false:
      → newProgress = min(subGoal.progress + habitContribution, 100)
      → GoalsDao.updateSubGoalProgress(subGoal.id, newProgress)
      → recalculateAndPersistGoalProgress(subGoal.goalId)
      → emit GoalProgressUpdatedEvent(goalId, progress)
```

Note: habitContribution is a fixed increment (e.g., 10 per check-in) or the sub-goal reaches 100 if the habit check-in represents completion.

### 5b. SleepLogSavedEvent

```
onSleepLogSaved(event):
  → GoalsDao.getSubGoalsLinkedTo('sleep', event.sleepLogId)
  → for each subGoal where isOverridden = false:
      → newProgress = event.sleepScore  [0–100 direct map]
      → GoalsDao.updateSubGoalProgress(subGoal.id, newProgress)
      → recalculateAndPersistGoalProgress(subGoal.goalId)
      → emit GoalProgressUpdatedEvent(goalId, progress)
```

### 5c. MoodLoggedEvent

```
onMoodLogged(event):
  → GoalsDao.getSubGoalsLinkedTo('mental', event.moodLogId)
  → for each subGoal where isOverridden = false:
      → newProgress = event.level  [0–100 direct map]
      → GoalsDao.updateSubGoalProgress(subGoal.id, newProgress)
      → recalculateAndPersistGoalProgress(subGoal.goalId)
      → emit GoalProgressUpdatedEvent(goalId, progress)
```

---

## Flow 6: Update Sub-Goal Progress (Manual)

```
updateSubGoalProgress(subGoalId, newProgress):
  → validateProgress(newProgress)  [0–100]
  → GoalsDao.getSubGoal(subGoalId)
  → if not found → NotFoundFailure
  → GoalsDao.updateSubGoalProgress(subGoalId, newProgress, isOverridden=true)
  → recalculateAndPersistGoalProgress(subGoal.goalId)
  → emit GoalProgressUpdatedEvent(goalId, weightedProgress)
  → Return Success(null)
```

---

## UI Flow: Goals Overview Screen

```
GoalsOverviewScreen loads:
  → GoalsDao.watchActiveGoals() [stream]
  → Groups by status (active first)
  → Filters by categoryFilter (optional)
  → Sorts active goals by targetDate ASC (nulls last), then by name
  → Displays GoalCard per goal with progress bar + category chip
```

## UI Flow: Goal Detail Screen

```
GoalDetailScreen(goalId) loads:
  → GoalsDao.watchGoal(goalId)      [stream for goal]
  → GoalsDao.watchSubGoals(goalId)  [stream for sub-goals]
  → GoalsDao.watchMilestones(goalId) [stream for milestones]
  → Milestones timeline: horizontal scrollable, sorted by targetProgress ASC
  → Completed milestones show completedAt date
  → Sub-goals list with weight display and progress slider (if no linkedModule or isOverridden)
```
