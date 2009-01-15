# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{happymapper}
  s.version = "0.1.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker"]
  s.date = %q{2009-01-04}
  s.description = %q{object to xml mapping library}
  s.email = ["nunemaker@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "License.txt", "Manifest.txt", "PostInstall.txt", "README.txt", "TODO.txt"]
  s.files = ["History.txt", "License.txt", "Manifest.txt", "PostInstall.txt", "README.txt", "Rakefile", "TODO.txt", "config/hoe.rb", "config/requirements.rb", "examples/amazon.rb", "examples/current_weather.rb", "examples/post.rb", "examples/twitter.rb", "happymapper.gemspec", "lib/happymapper.rb", "lib/happymapper/attribute.rb", "lib/happymapper/element.rb", "lib/happymapper/item.rb", "lib/happymapper/version.rb", "lib/libxml_ext/libxml_helper.rb", "script/console", "script/destroy", "script/generate", "script/txt2html", "setup.rb", "spec/fixtures/address.xml", "spec/fixtures/current_weather.xml", "spec/fixtures/pita.xml", "spec/fixtures/posts.xml", "spec/fixtures/statuses.xml", "spec/happymapper_attribute_spec.rb", "spec/happymapper_element_spec.rb", "spec/happymapper_item_spec.rb", "spec/happymapper_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks/deployment.rake", "tasks/environment.rake", "tasks/rspec.rake", "tasks/website.rake", "website/css/common.css", "website/index.html"]
  s.has_rdoc = true
  s.homepage = %q{http://happymapper.rubyforge.org}
  s.post_install_message = %q{}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{happymapper}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{object to xml mapping library}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end