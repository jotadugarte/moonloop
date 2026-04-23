require "rails_helper"

RSpec.describe "Public catalogs views", type: :system do
  let(:owner) { create(:user, password: "Password123!") }
  let(:viewer) { create(:user, password: "Password123!") }

  before do
    driven_by(:rack_test)

    visit sign_in_path
    fill_in I18n.t("activerecord.attributes.user.email"), with: viewer.email
    fill_in I18n.t("activerecord.attributes.user.password"), with: "Password123!"
    click_button I18n.t("sessions.new.submit")
  end

  # [REQ-MENU-006]
  describe "public menus index" do
    context "with publicly shared menus" do
      let!(:menu) { Menu.create!(user: owner, name: "Menú público test", publicly_shareable: true) }

      it "renders an <article> element for each menu item" do
        visit public_menus_path

        expect(page).to have_css("article", minimum: 1)
      end

      it "each menu item has a visible, descriptive link" do
        visit public_menus_path

        expect(page).to have_link(menu.name, href: public_menu_path(menu))
      end
    end

    context "with no menus" do
      it "renders the page heading" do
        visit public_menus_path

        expect(page).to have_css("h1", text: I18n.t("public_menus.index.heading"))
      end
    end
  end

  # [REQ-EXR-006]
  describe "public exercise routines index" do
    context "with publicly shared routines" do
      let!(:routine) do
        r = ExerciseRoutine.new(user: owner, name: "Rutina pública test", publicly_shareable: true)
        r.exercise_routine_lines.build(weekday: 0, position: 1, label: "Push-up")
        r.save!
        r
      end

      it "renders an <article> element for each routine item" do
        visit public_exercise_routines_path

        expect(page).to have_css("article", minimum: 1)
      end

      it "each routine item has a visible, descriptive link" do
        visit public_exercise_routines_path

        expect(page).to have_link(routine.name, href: public_exercise_routine_path(routine))
      end
    end

    context "with no routines" do
      it "renders the page heading" do
        visit public_exercise_routines_path

        expect(page).to have_css("h1", text: I18n.t("public_exercise_routines.index.heading"))
      end
    end
  end

  # [REQ-RPT-001, REQ-RPT-002, REQ-RPT-003]
  describe "reports page" do
    it "renders the main heading" do
      visit informes_path

      expect(page).to have_css("h1", text: I18n.t("reports.show.heading"))
    end

    it "renders the three report sections with semantic ids" do
      visit informes_path

      expect(page).to have_css("section#cumplimiento")
      expect(page).to have_css("section#rachas")
      expect(page).to have_css("section#peso")
    end

    it "renders internal section navigation links" do
      visit informes_path

      expect(page).to have_link(I18n.t("reports.show.nav_fulfillment"), href: "#cumplimiento")
      expect(page).to have_link(I18n.t("reports.show.nav_streaks"),     href: "#rachas")
      expect(page).to have_link(I18n.t("reports.show.nav_weight"),      href: "#peso")
    end
  end
end
