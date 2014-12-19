namespace :deploy do
  namespace :before do

    desc <<-DESC
[Internal] Ensure that deploy code is tagged.

For the production deploy allows check that current Capiche repository
is tagged by Semver-compliant tag.

Tag format must be vA.B.C, othervise deploy cancelled.

Source #{path_to __FILE__}

DESC

    task :ensure_tag do
      tag = run_locally("git describe --exact-match --tags $(git log -n1 --pretty='%h') || true ").chomp
      abort "#{'*'*80}\n          Please checkout tagged revision for the deploy\n#{ '*'*80 }\n" unless tag =~/^v\d+\.\d\.+\d/
      set :capiche_release_tag, tag
    end
  end
end

before "chefsolo:setup", "deploy:before:ensure_tag",   :except => config_names
# Incase if there's no chefsolo:setup
on :start,  "chefsolo:setup",   :except => (config_names << "chefsolo:setup")
