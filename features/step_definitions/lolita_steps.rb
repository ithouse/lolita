Given /^I am lolita user$/ do
  @profile = Profile.create
end

Then /^print output$/ do
  save_and_open_page
end
