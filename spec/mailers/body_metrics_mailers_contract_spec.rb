# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mailer body metrics contract (REQ-PROF-003)" do
  # [REQ-PROF-003]
  it "loads BodyMetricsHelper on ApplicationMailer and forbids raw metric columns in templates" do
    app_mailer = Rails.root.join("app/mailers/application_mailer.rb").read
    expect(app_mailer).to include("helper BodyMetricsHelper"),
      "Add `helper BodyMetricsHelper` to ApplicationMailer so templates can use format_body_weight / format_body_height_snapshot"

    paths = Dir[Rails.root.join("app/views/**/*_mailer/**/*.erb")]
    expect(paths).not_to be_empty

    forbidden = %r{<%=\s*@(user|weight_log)\.(?:weight_kg|height_cm|current_weight_kg)\s*%>}

    paths.each do |path|
      next if path.include?("/layouts/")

      expect(File.read(path)).not_to match(forbidden),
        "Use format_body_weight / format_body_height_snapshot with @user in #{path}"
    end
  end
end
