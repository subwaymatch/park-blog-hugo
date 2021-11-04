---
title: "Duplicating a Supabase Postgres Schema to a New Project"
date: 2021-11-04
categories:
  - Postgres
tags:
  - postgres
  - supabase
---

Looking to duplicate a Postgres database in a Supabase project to another project? Using `pg_dump` and `pg_restore` won't work because you only have superuser access through the Supabase dashboard. Here's a workflow of duplicating a Supabase Postgres schema using pgAdmin and the Supabase dashboard.

## Exporting Schema

You can use the `pg_dump` in a CLI as well.

### Right-click on pgAdmin's public schema and click Backup

![image](https://user-images.githubusercontent.com/1064036/140382400-0792e227-4d7b-48e1-bfc1-bba413f1038e.png)

### Enter a filename and choose Plain format

![image](https://user-images.githubusercontent.com/1064036/140382436-ca1b821f-0f44-4d58-a537-863569f3ad5b.png)

### Toggle "Only schema" dump option

If you need both the schema and full data, you can choose to dump pre-data, data, and post-data. If you only need the schema, the selections shown below will work.

Run the backup.

![image](https://user-images.githubusercontent.com/1064036/140382461-55eb0027-5428-4042-b217-920228991dda.png)

This should generate a file named `my_backup`.

![image](https://user-images.githubusercontent.com/1064036/140382500-7dbfe7be-0af7-455b-9097-ab361e480fcc.png)

Content of `my_backup`:

```sql
--
-- PostgreSQL database dump
--

-- Dumped from database version 13.3
-- Dumped by pg_dump version 13.3

-- Started on 2021-11-04 09:35:27

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- and so on...
```

## Manually install extensions

If you have queries that require a Postgres extension that is not installed by default in Supabase, you will have to manually install those extensions through the Supabase dashboard **before** running dumped SQL code.

## Importing Schema

This step must be done in the Supabase dashboard.

### Create a New Query tab

![image](https://user-images.githubusercontent.com/1064036/140382605-22f32634-c92a-4eb2-86e3-5ca3dd1dddaf.png)

### Copy SQL code from `my_dump`

Select the `CREATE`/`ALTER` queries you'd like to run and copy them to the query pane.

Run once you're ready.

![image](https://user-images.githubusercontent.com/1064036/140382636-e6e68b39-65f7-4581-b915-be4c2284091d.png)

That should duplicate your schema from the original Supabase project.
