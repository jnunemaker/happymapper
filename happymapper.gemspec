# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{happymapper}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker"]
  s.date = %q{2009-10-04}
  s.description = %q{object to xml mapping library}
  s.email = %q{nunemaker@gmail.com}
  s.extra_rdoc_files = ["lib/happymapper/attribute.rb", "lib/happymapper/element.rb", "lib/happymapper/item.rb", "lib/happymapper/version.rb", "lib/happymapper.rb", "README", "TODO"]
  s.files = ["examples/amazon.rb", "examples/current_weather.rb", "examples/dashed_elements.rb", "examples/multi_street_address.rb", "examples/post.rb", "examples/twitter.rb", "happymapper.gemspec", "History", "How", "to", "release", "lib/happymapper/attribute.rb", "lib/happymapper/element.rb", "lib/happymapper/item.rb", "lib/happymapper/version.rb", "lib/happymapper.rb", "License", "Manifest", "Rakefile", "README", "spec/fixtures/address.xml", "spec/fixtures/analytics.xml", "spec/fixtures/commit.xml", "spec/fixtures/current_weather.xml", "spec/fixtures/family_tree.xml", "spec/fixtures/multi_street_address.xml", "spec/fixtures/multiple_namespaces.xml", "spec/fixtures/nested_namespaces.xml", "spec/fixtures/pita.xml", "spec/fixtures/posts.xml", "spec/fixtures/product_default_namespace.xml", "spec/fixtures/product_no_namespace.xml", "spec/fixtures/product_single_namespace.xml", "spec/fixtures/radar.xml", "spec/fixtures/statuses.xml", "spec/happymapper_attribute_spec.rb", "spec/happymapper_element_spec.rb", "spec/happymapper_item_spec.rb", "spec/happymapper_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "TODO", "website/css/common.css", "website/index.html"]
  s.homepage = %q{http://happymapper.rubyforge.org}
  s.post_install_message = %q{May you have many happy mappings!}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Happymapper", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{happymapper}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{object to xml mapping library}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<libxml-ruby>, ["= 1.1.3"])
    else
      s.add_dependency(%q<libxml-ruby>, ["= 1.1.3"])
    end
  else
    s.add_dependency(%q<libxml-ruby>, ["= 1.1.3"])
  end
end
