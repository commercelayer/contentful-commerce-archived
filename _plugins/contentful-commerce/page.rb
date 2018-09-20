module ContentfulCommerce
  class Page < Jekyll::Page
    def initialize(site, dir, name, template, data={})
      @site = site
      @base = site.source
      @dir = dir
      @name = name.parameterize + ".html"

      self.process(@name)
      self.read_yaml(File.join(@base, "_templates"), template + ".html")
      self.data["title"] = name
      self.data.merge!(data)
    end
  end
end
