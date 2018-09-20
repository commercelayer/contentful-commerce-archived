module ContentfulCommerce
  module Filters
    def parameterize(input)
      input.parameterize
    end

    def product_slug(product)
      (product["name"] || product["reference"]).parameterize
    end

    def image_path(input)
      input || "/assets/images/no-image.svg"
    end

    def back_url(url)
      url.split("/")[0..-2].join("/")
    end

    def locales(site)
      site.data["contentful"]["spaces"].keys
    end

    def countries(site, locale)
      site.data["contentful"]["spaces"][locale]["country"]
    end

  end
end

Liquid::Template.register_filter(ContentfulCommerce::Filters)
