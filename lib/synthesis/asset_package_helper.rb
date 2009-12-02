module Synthesis
  module AssetPackageHelper
    IE_STYLESHEET_LIMIT = 31 # this is the maximum number of stylesheet tags per page or import statements per style tag
    
    def should_merge?
      AssetPackage.merge_environments.include?(RAILS_ENV)
    end

    def javascript_include_merged(*sources)
      options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }

      if sources.include?(:defaults) 
        sources = sources[0..(sources.index(:defaults))] + 
          ['prototype', 'effects', 'dragdrop', 'controls'] + 
          (File.exists?("#{RAILS_ROOT}/public/javascripts/application.js") ? ['application'] : []) + 
          sources[(sources.index(:defaults) + 1)..sources.length]
        sources.delete(:defaults)
      end

      sources.collect!{|s| s.to_s}
      sources = (should_merge? ? 
        AssetPackage.targets_from_sources("javascripts", sources) : 
        AssetPackage.sources_from_targets("javascripts", sources))
      
      sources.collect {|source| javascript_include_tag(source, options) }.join("\n")
    end

    def stylesheet_link_merged(*sources)
      options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }

      sources.collect!{|s| s.to_s}
      sources = (should_merge? ? 
        AssetPackage.targets_from_sources("stylesheets", sources) : 
        AssetPackage.sources_from_targets("stylesheets", sources))

      if sources.size > IE_STYLESHEET_LIMIT
        # need to use the import method so that IE doesn't just sliently drop styles
        # after the limit has been reached
        out = ''
        sources.in_groups_of(IE_STYLESHEET_LIMIT).each do |group|
          group_imports = group.map do |source|
            if source
              "@import url(#{stylesheet_path(source)});"
            else
              nil
            end
          end.compact.join("\n")
          out += content_tag(:style, "<!-- #{group_imports} -->", :type => 'text/css', :media => 'all')
        end
        return out
      else
        return sources.collect { |source| stylesheet_link_tag(source, options) }.join("\n")    
      end
    end

  end
end