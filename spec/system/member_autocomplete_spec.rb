require "rails_helper"

RSpec.describe "Member autocomplete", type: :system do
  let!(:owner) { create(:user, :admin, name: "Gandalf", email: "gandalf@example.com") }
  let!(:project) { create(:project, user: owner, title: "Save Rohan") }
  let!(:member_candidate) { create(:user, name: "Arwen Undomiel", email: "arwen@example.com") }

  before do
    driven_by :screenshot_desktop
    visit verify_session_path(token: owner.generate_magic_token!)
  end

  it "selects an existing user and links unmatched input to invitations" do
    visit project_path(project)

    member_input = find("input[placeholder='Add by email address']")
    member_input.fill_in with: "arw"

    expect(page).to have_text("Arwen Undomiel")
    click_button "Arwen Undomiel"
    expect(member_input.value).to eq(member_candidate.email)

    member_input.fill_in with: "eowyn@example.com"

    expect(page).to have_text("No matching user found")
    click_link "No matching user found"
    expect(page).to have_current_path(new_invitation_path(email: "eowyn@example.com"))
    expect(find_field("Email address").value).to eq("eowyn@example.com")
  end
end
