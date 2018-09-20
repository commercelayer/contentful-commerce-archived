module ContentfulCommerce

  class Generator < Jekyll::Generator

    def generate(site)

      site.config['env'] = ENV

      locales(site).each do |locale|

        space = site.data["contentful"]["spaces"][locale]

        space["country"].each do |country|

          base_dir = [country["code"], locale].join("/").downcase
          add_page(site, base_dir, "index", "catalogue", "country" => country, "locale" => locale)

          country["catalogue"]["categories"].each do |category|
            add_page(site, base_dir, category["name"], "category", "country" => country, "locale" => locale, "category" => category)

            products(category, country).each do |product|
              category_dir = [base_dir, category["name"].parameterize].join("/").downcase
              add_page(site, category_dir, product_name(product), "product", "country" => country, "locale" => locale, "category" => category, "product" => product)
            end

          end

        end

      end

    end

    private
    def locales(site)
      site.data["contentful"]["spaces"].keys
    end

    def product_name(product)
      product["name"] || product["reference"]
    end

    def products(category, country)
      products_rel = "products_#{country["code"].downcase}"
      products_exist = category[products_rel] && category[products_rel].any?
      products_exist ? category[products_rel] : category["products"]
    end

    def add_page(site, dir, name, template, data={})
      site.pages << Page.new(site, dir, name, template, data)
    end

  end

end
