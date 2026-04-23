# Task: Web Views (Crear vistas sencillas)

## Context
Item 39 from ROADMAP: `Crear vistas sencillas de pantallas para poder ver la app en la web`.
We need to create the main application layout and fundamental views (Mi Día, Perfil, Catálogos, Informes) using semantic HTML, ensuring it is responsive, accessible (using labels), and plays well with Hotwire (422 responses).

## Domain Model
*(No new domain entities required; this task is strictly UI/View layer over existing backend)*

## Implementation Plan

<implementation_plan>
<step id="1" status="complete">
[Feature] Main Application Layout
- Write a failing system test (`spec/system/layout_spec.rb`) verifying that the navigation bar exists and contains accessible links to Mi Día, Catálogos, Informes, and Perfil.
- Modify `app/views/layouts/application.html.erb` to include a semantic `<nav>` with the required links and ensure the mobile viewport meta tag is present.
- Run tests to verify the layout works.
</step>
<step id="2" status="complete">
[Feature] Mi Día View enhancements
- Write a failing system test (`spec/system/my_day_spec.rb`) verifying the local date is clearly displayed at the top and all habit inputs have proper `<label>` elements.
- Modify `app/views/my_day/show.html.erb` and its related partials to add the local date and semantic labels.
- Audit `HabitCompletionsController` to ensure it returns `422 Unprocessable Entity` on errors.
- Run tests to verify Mi Día is accessible and handles Turbo form submissions correctly.
</step>
<step id="3" status="complete">
[Feature] Catalogs and Reports Views structure
- Write failing system tests (`spec/system/catalogs_spec.rb` and `spec/system/reports_spec.rb`) verifying semantic HTML elements and that all interactive elements have clear, accessible text.
- Modify `app/views/public_menus/index.html.erb`, `app/views/public_exercise_routines/index.html.erb`, and `app/views/reports/show.html.erb` to use basic semantic tags (`<article>`, `<ul>`, `<table>`).
- Run tests to verify catalog and report views.
</step>
<step id="4" status="pending">
[Feature] Profile and Forms accessibility
- Write a failing system test (`spec/system/profile_spec.rb`) verifying all form inputs have associated `<label>` tags and that validation errors correctly repaint via Hotwire (verifying 422 status).
- Modify `app/views/profiles/show.html.erb`, `app/views/profiles/edit.html.erb` (and any other core forms) to add semantic labels.
- Run tests to verify profile views.
</step>
</implementation_plan>
