module ContentfulCommerce

  class Generator < Jekyll::Generator

    def generate(site)

      setup_commercelayer_env(site)

      locales(site).each do |locale|

        space = site.data["contentful"]["spaces"][locale]

        space["country"].each do |country|

          base_dir = [country["code"], locale].join("/").downcase
          add_page(site, base_dir, "index", "catalogue", "country" => country, "locale" => locale)

          country["catalogue"]["categories"].each do |category|
            category_dir = base_dir + "/#{category["name"].parameterize}"
            add_page(site, category_dir, "index", "category", "country" => country, "locale" => locale, "category" => category)

            products(category, country).each do |product|
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

    def setup_commercelayer_env(site)
      site.config['commercelayer_base_url'] = ENV['COMMERCELAYER_BASE_URL']
      site.config['commercelayer_client_id'] = ENV['COMMERCELAYER_CLIENT_ID']
      site.config['site_base_url'] = ENV['SITE_BASE_URL']
    end

  end

end
