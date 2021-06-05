---
title: "PostgreSQL Trigger: Calculate the Difference between Two Timestamps in Seconds"
date: 2021-06-05
categories:
  - Postgres
---

A SQL trigger is a function that is automatically invoked when an event occurs. To set a trigger, you specify the following:

- which table(s) and column(s) to listen to
- which actions to listen to (e.g., `INSERT`, `UPDATE`, `DELETE`)
- what function or procedure to invoke.

Triggers have many use cases. Some examples are:

- **Create an audit trail**: You have a table that contains sensitive information. You create a trigger to record all changes (what change has been made, which user has made the change, when the change has been made) to a separate table.
- **Integrity check**: Before adding a student to a class roster, you want to ensure that the student's previous course enrollments fulfill prerequisites.
- **Derive additional data**: You have a table that contains the start and the end time of an online exam for test-takers. When a student is done with the exam, you want to calculate how long the student took to complete the exam using the start and end timestamps. Note that this can also be implemented using a generated column.

This post will implement the last example. You create a test-taking web app where you mark the start time (`start_time`) when the student hits the "Start" button. Once the student finishes taking the exam and clicks on "Submit", the web app will mark the finish time (`end_time`). You want to automatically calculate how long the test-taker spent on the exam in **seconds**.

`my_table` columns:

| Column     | Type      |
| ---------- | --------- |
| id         | int       |
| start_time | timestamp |
| end_time   | timestamp |
| duration   | integer   |

First, define a row-level trigger that runs on each row.

```sql
CREATE OR REPLACE FUNCTION update_total_duration()
RETURNS TRIGGER AS $body$
BEGIN
  IF NEW.start_time IS NOT NULL AND NEW.end_time IS NOT NULL THEN
    NEW.duration = EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) AS INTEGER;
  END IF;
  ****RETURN NEW;
END;
$body$ LANGUAGE plpgsql;
```

Then, add a statement-level trigger that runs whenever the `end_time` field has been updated.

```sql
CREATE TRIGGER on_end_time_update BEFORE
UPDATE OF end_time ON my_table
FOR EACH ROW EXECUTE PROCEDURE update_total_duration();
```

Voilà! This trigger will now automatically calculate the `duration` whenever a test-taker completes the test.
