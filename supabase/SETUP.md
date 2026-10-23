# Supabase setup for Four Fold Event Management

## Important before you begin

The SQL in `schema.sql` creates the production data model and admin-only Row Level Security (RLS) policies. It has **not** been run against a Supabase project from this repository change. Review the target project first; do not use the unrelated Loopify or E2FIT project unless you deliberately choose it for Four Fold.

## 1. Create or select a dedicated project

In the Supabase dashboard, create a project named `Four Fold Events` if you do not already have a dedicated project. Check the estimated price and plan before confirming creation. A free plan may be suitable for a prototype, but review its current limits and inactivity/pause behavior before relying on it for business operations.

## 2. Apply the schema

1. Open the dedicated project.
2. Open **SQL Editor**.
3. Review `schema.sql` in this folder.
4. Paste and run it in the intended project.
5. Verify the tables under **Table Editor** and inspect policies under **Authentication / Policies** or the table's RLS policy view.
6. Run the Supabase security advisor and address warnings before real data is entered.

This migration creates: clients, enquiries, events, quotations, quotation items, payments, vendors, event tasks, gallery items and an audit log. Monetary amounts use integer paise to avoid floating-point currency rounding.

## 3. Create the first admin securely

The policy expects a trusted JWT claim: `app_metadata.role = "admin"`.

- Create the intended owner's account through Supabase Auth.
- Set the role in trusted app metadata through a trusted admin/dashboard process. Do not use user-editable `user_metadata` for authorization.
- Sign out and sign back in or refresh the session so the updated app metadata is present in the JWT.
- Test that an unauthed user and a normal authenticated user cannot read or write any business tables.
- Confirm that the owner account can access the tables.

Never add a public sign-up flow that lets anyone set their own admin role. Never put a service-role/secret key in browser code, GitHub, or a public environment variable.

## 4. Frontend integration still needed

The current `admin.html` is a local-storage prototype and does not yet call Supabase. To connect it safely:

1. Add a pinned version of `@supabase/supabase-js` and commit the lockfile, or load a reviewed pinned browser build.
2. Configure the project URL and publishable key as public client configuration only. The publishable key is not a password; RLS is the data access boundary.
3. Add a login page using Supabase Auth. Protect the dashboard until a verified session exists; provide logout and a clear session-expired state.
4. Replace local-storage CRUD in `admin.html` with database calls to the tables above.
5. Add validation and error handling. Never report success if a database request fails.
6. Keep business records private; do not create permissive public RLS policies.
7. Add a secure server-side intake endpoint only if you want website submissions to appear automatically in the dashboard. A `wa.me` link only opens WhatsApp and cannot automatically ingest messages.

## 5. Production verification checklist

- [ ] Unauthenticated REST/API requests cannot read or mutate private records.
- [ ] Authenticated user without `app_metadata.role = "admin"` is denied.
- [ ] Owner admin can create, edit, view and delete test records.
- [ ] An update cannot change the authorization role or ownership claims.
- [ ] Quotations and payment balances reconcile against individual payment rows.
- [ ] No service-role key appears in repository files or browser requests.
- [ ] Backups and restore have been tested.
- [ ] No real customer data is loaded until all tests pass.

The SQL is an initial single-business schema. It does not yet include a database trigger for audit log entries, a quotation-number sequence, PDF generation, a WhatsApp webhook or automated backups; those should be added and tested as separate milestones.
