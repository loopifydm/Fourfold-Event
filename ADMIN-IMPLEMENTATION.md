# Four Fold Event Management — implementation plan

## Current branch

This implementation is prepared on `feature/admin-dashboard-mvp` so it does not replace or disrupt the live `main` branch.

- Existing public website: `index.html` (left unchanged)
- New admin prototype: `admin.html`
- Existing brand asset referenced by both pages: `assets/fourfold-logo.jpg`
- Business WhatsApp: `+91 93609 31245` (`919360931245` in WhatsApp URLs)
- Market: Coimbatore, Tamil Nadu
- Brand direction: luxury charcoal, champagne gold and ivory; Cormorant Garamond + DM Sans; responsive, larger readable typography.

## What the prototype does

The admin page includes:
- Overview cards for enquiries, upcoming events, confirmed bookings and outstanding balances.
- Enquiry records and follow-up statuses.
- Booking records with event date, venue, guest count, total, advance, balance and status.
- Quotation records with reference number, estimated amount, validity and status.
- A payment summary based on booking totals and advances.
- Client list derived from enquiries and bookings.
- JSON export and local demo-data reset.
- Mobile navigation and add/edit/delete actions.

**Important:** this is a front-end prototype only. Records are saved to the current browser's local storage. It has no login, shared database, secure access control, automated intake from WhatsApp, PDF quote generation, payment gateway or reliable backups. Do not enter real customer information into it yet. The public enquiry form currently opens a prefilled WhatsApp message for the customer to send; it does not automatically copy that message into the admin page.

## Production architecture recommended

1. **Public website:** keep the existing lightweight website and improve it without removing current sections, links or form behavior.
2. **Hosting:** GitHub Pages can host the static public website for free when the repository/account plan and visibility meet GitHub's requirements. A static host cannot itself provide a secure server-side admin database.
3. **Authentication and database:** connect Supabase Auth + Postgres. Restrict the admin route to authenticated users and enable row-level security policies for all business tables. Keep service-role secrets out of browser code.
4. **Tables:** `profiles`, `clients`, `enquiries`, `events`, `quotations`, `quotation_items`, `payments`, `vendors`, `event_tasks`, `gallery_items`, and `audit_log`.
5. **Booking lifecycle:** New enquiry → Contacted → Quotation sent → Confirmed booking → Event completed. Support cancellation with an audit trail rather than silently deleting paid/confirmed business records.
6. **Money:** store integer paise or decimal-safe numeric INR amounts; calculate balance as total less recorded payments, not just a single advance field. Keep payment date, method, reference and receipt metadata.
7. **Quotes:** generate printable/PDF quotations with a sequential quote number, event scope, itemised services, taxes/discounts where applicable, terms, validity and payment schedule.
8. **Notifications:** use a server-side function or approved WhatsApp Business integration if you want submissions to arrive automatically. A `wa.me` link alone cannot ingest messages or guarantee that a visitor sends the form.
9. **Backups:** configure database backups/export and test restore. The free Supabase plan has quota and inactivity limitations, so review the current plan details before relying on it for production records.
10. **Security and launch checks:** private admin access, row-level security tests, validation, spam protection, consent/privacy notice, mobile accessibility, and a tested restore process.

## Safe deployment sequence

1. Review this feature branch and compare it with `main`.
2. Preview `index.html` and `admin.html` locally; verify the official logo asset exists and renders.
3. Merge only after review. Do not publish the prototype as a secure admin system.
4. Configure GitHub Pages for the public site (Settings → Pages); the project URL will be under the repository owner's GitHub Pages domain unless a custom domain is configured.
5. Configure Supabase in a separate setup step, add only public project URL/anon key to the frontend environment, and implement strict row-level security. Never commit service-role keys.
6. Replace local-storage persistence with authenticated database operations before handling actual client records.
7. Test enquiry, booking, quote, payment, permissions, export, mobile layout and backup/restore.

## Suggested next implementation milestones

- **Milestone 1:** review the visual admin prototype and merge it only when approved.
- **Milestone 2:** secure admin sign-in and Supabase schema/RLS.
- **Milestone 3:** connect enquiries and bookings to the database.
- **Milestone 4:** quotation PDF, multiple payment records and receipt generation.
- **Milestone 5:** calendar, task/vendor management, client follow-ups and automated backups.
- **Milestone 6:** production testing and launch.

No Supabase project credentials were supplied, so this branch intentionally does not pretend that live database persistence or secure authentication is already configured.
