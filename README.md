# Contentful bootstrap

- Create free account on Contentful
- Create empty space
- Get Organization ID, Content management token (Generate personal token), Space ID and Content Delivery API (Access token)

``` shell
$ touch ~/.contentfulrc
```

```
# .contentfulrc

[global]
CONTENTFUL_ORGANIZATION_ID = <YOUR_CONTENTFUL_ORGANIZATION_ID>
CONTENTFUL_MANAGEMENT_ACCESS_TOKEN = <YOUR_CONTENTFUL_MANAGEMENT_ACCESS_TOKEN>

[Contentful Commerce]
CONTENTFUL_SPACE_ID = <YOUR_SPACE_ID>
CONTENTFUL_DELIVERY_ACCESS_TOKEN = <YOUR_CONTENTFUL_DELIVERY_ACCESS_TOKEN>
```

- download content_model.json from repo

$ gem install contentful_bootstrap
$ contentful_bootstrap update_space <YOUR_SPACE_ID> -j path/to/content_model.json

- content types overview

# Commerce Layer export

- Create free account on Commerce Layer
- Create a test organization
- Get client id, client_secret, base endpoint from SKU Exporter application

``` shell
$ touch ~/.commercelayer-cli.yml
```

``` yaml
# .commercelayer-cli.yml

commercelayer:
  site: <your_base_endpoint>
  client_id: <your_client_id>
  client_secret: <your_client_secret>
contentful:
  space: <your_space_id>
  access_token: <your_access_token>
```

``` shell
$ commercelayer-cli export contentful
```

# Catalogue management

Localization, product enrichment, merchandising, markets

# Jekyll

``` shell
$ gem install bundler jekyll
$ jekyll new contentful-commerce --blank
$ cd contentful-commerce
$ rm -r _drafts _posts
$ bundle init
```

``` ruby
# Gemfile

# [...]

group :jekyll_plugins do
  gem "jekyll-contentful-data-import"
  gem "activesupport", require: "active_support/inflector"
end
```

``` shell
$ bundle
```

``` shell
$ touch _config.yml
```

``` yaml
# _config.yml

contentful:
  spaces:
    - en-US:
        space: ENV_CONTENTFUL_SPACE_ID
        access_token: ENV_CONTENTFUL_DELIVERY_ACCESS_TOKEN
        all_entries: true
        cda_query:
          locale: "en-US"
    - it:
        space: ENV_CONTENTFUL_SPACE_ID
        access_token: ENV_CONTENTFUL_DELIVERY_ACCESS_TOKEN
        all_entries: true
        cda_query:
          locale: "it"
```

```
# .bash_profile

[...]

export CONTENTFUL_SPACE_ID="<YOUR_SPACE_ID>"
export CONTENTFUL_DELIVERY_ACCESS_TOKEN="<YOUR_CONTENTFUL_DELIVERY_ACCESS_TOKEN>"
```

``` shell
$ bundle exec jekyll contentful
```

# Generator, page and filters

``` shell
$ mkdir -p _plugins/contentful-commerce
$ touch _plugins/contentful-commerce/generator.rb
$ touch _plugins/contentful-commerce/page.rb
$ touch _plugins/contentful-commerce/filters.rb
```

``` ruby
# generator.rb

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
```

``` ruby
# page.rb

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
```

``` ruby
# filters.rb

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
```

# Views

``` shell
$ touch _layouts/default.html
$ mkdir _includes
$ touch _includes/country_selector.html
$ touch _includes/language_selector.html
$ touch index.html
$ mkdir -p _templates
$ touch _templates/catalogue.html
$ touch _templates/category.html
$ touch _templates/product.html
```

``` html
<!--  _layouts/default.html -->

<!DOCTYPE html>
<html class="has-navbar-fixed-top">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Contentful Commerce</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.1/css/bulma.min.css">
    <link rel="stylesheet" href="/assets/stylesheets/main.css">
    <script defer src="https://use.fontawesome.com/releases/v5.1.0/js/all.js"></script>
  </head>
  <body>
    <nav class="navbar is-dark is-fixed-top">
      <div class="container">
        <div class="navbar-brand">
          <a href="/" class="navbar-item">
            <img src="/assets/images/contentful.svg" alt="Contentful" id="contentful-logo">
            <span class="icon"> <i class="fas fa-plus"></i> </span>
            <img src="/assets/images/commercelayer.svg" alt="Commerce Layer" id="commercelayer-logo">
          </a>
        </div>
        <div class="navbar-menu">
          <div class="navbar-end">
            {% include country_selector.html %}
            {% include language_selector.html %}
          </div>
        </div>
      </div>
    </nav>
    <section class="section" id="main">
      <div class="container">
        {{ content }}
      </div>
    </section>
    <footer class="footer">
      <div class="content has-text-centered">
        <p>
          <strong>Like what you see?</strong>
           Read the step-by-step tutorial on the <a href="https://www.contentful.com/blog/">Contentful's blog</a>.
        </p>
      </div>
    </footer>
  </body>
</html>
```

``` html
<!--  _includes/country_selector.html -->

{% if page.country %}
  <div class="navbar-item has-dropdown is-hoverable">
    <a class="navbar-link">
      Shipping to:&nbsp;
      <img src="/assets/images/countries/{{page.country.code | downcase }}.svg", width="20">&nbsp;
    </a>
    <div class="navbar-dropdown">
      {% assign countries = site | countries: page.locale %}
      {% for country in countries %}
        <a class="navbar-item" href="/{{country.code | downcase}}/{{country.default_locale | downcase }}">
          <img src="/assets/images/countries/{{country.code | downcase }}.svg", width="20">&nbsp;
          {{ country.name }}
        </a>
      {% endfor %}
    </div>
  </div>
{% endif %}
```

``` html
<!--  _includes/language_selector.html -->

{% if page.locale %}
  <div class="navbar-item has-dropdown is-hoverable">
    <a class="navbar-link">
      Language:&nbsp;
      <img src="/assets/images/languages/{{page.locale | downcase }}.svg", width="20">
    </a>
    <div class="navbar-dropdown is-right">
      {% assign locales = site | locales %}
      {% for locale in locales %}
        <a class="navbar-item" href="/{{page.country.code | downcase}}/{{locale | downcase }}">
          <img src="/assets/images/languages/{{locale | downcase }}.svg", width="20">&nbsp;
          {{ site.t[page.locale]["languages"][locale] | capitalize}}
        </a>
      {% endfor %}
    </div>
  </div>
{% endif %}
```

- add /assets/images and /assets/stylesheets

``` html
<!--  index.html -->

---
layout: default
---

<h1 class="title">
  Welcome, developer!
</h1>
<p class="subtitle">
  Please select your shipping country
</p>

<div class="columns is-mobile">
  {% for country in site.data["contentful"]["spaces"]["en-US"]["country"] %}
    <div class="column is-half-mobile is-one-fifth-tablet">
      <a href="/{{country.code | parameterize}}/{{country.default_locale | parameterize }}">
        <img src="/assets/images/countries/{{country.code | parameterize}}.svg" alt="{{country.name}}" class="image">
      </a>
    </div>
  {% endfor %}
</div>
```

``` html
<!-- _templates/catalogue.html -->

---
layout: default
---

<nav class="breadcrumb" aria-label="breadcrumbs">
  <ul>
    <li><a href="/">Home</a></li>
    <li class="is-active"><a href="/">{{ site.t[page.locale]["categories"] | capitalize }}</a></li>
  </ul>
</nav>

<div class="columns is-multiline">
{% for category in page.country.catalogue.categories %}
  {% assign category_slug = category.name | parameterize %}
  <div class="column is-half-tablet is-one-quarter-desktop">
    <div class="box">
      <h2 class="has-text-weight-bold">{{category.name}}</h2>
      <a href="{{category_slug}}">
        <img src="{{ category.image.url | image_path }}" alt="{{ category.name }}">
      </a>
    </div>
  </div>
{% endfor %}
</div>
```

``` html
<!-- _templates/category.html -->

---
layout: default
---

<nav class="breadcrumb" aria-label="breadcrumbs">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="{{page.url | back_url }}">{{ site.t[page.locale]["categories"] | capitalize }}</a></li>
    <li class="is-active"><a href="{{page.url}}">{{ page.category.name }}</a></li>
  </ul>
</nav>

<div class="columns is-multiline is-mobile">

{% assign products_rel = "products" %}
{% assign products_rel_country = "products" | append: "_" | append: page.country.code | downcase %}
{% if page.category[products_rel_country] and page.category[products_rel_country] != empty %}
  {% assign products_rel = products_rel_country %}
{% endif %}

{% for product in page.category[products_rel] %}
  {% assign product_slug = product | product_slug %}

  <div class="column is-half-touch is-one-quarter-desktop">
    <div class="product-listing box">
      <a href="{{product_slug}}">
        <img src="{{ product.image.url | image_path }}" alt="{{ product.name }}">
      </a>
      <h2 class="has-text-weight-bold is-hidden-mobile">{{product.name}}</h2>
      <div class="is-size-7 is-hidden-mobile">{{product.reference}}</div>
    </div>
  </div>
{% endfor %}
</div>
```

``` html
<!-- _templates/product.html -->

---
layout: default
---

<nav class="breadcrumb" aria-label="breadcrumbs">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="{{page.url | back_url | back_url }}">{{ site.t[page.locale]["categories"] | capitalize }}</a></li>
    <li><a href="{{page.url | back_url }}">{{ page.category.name }}</a></li>
  </ul>
</nav>

<div class="columns">
  <div class="column is-two-thirds">
    <img src="{{page.product.image.url | image_path}}" alt="">
  </div>
  <div class="column">
    <h1 class="title">{{page.product.name}}</h1>

    <article class="message is-warning">
      <div class="message-body">
        Shopping goes here
      </div>
    </article>

  </div>
</div>
```

``` yaml
# _config.yml

t:
  en-US:
    add_to_bag: add to shopping bag
    available: available
    categories: categories
    continue_shopping: continue shopping
    days: days
    free_over: free over
    languages:
      en-US: english
      it: italian
    method: method
    out_of_stock: the requested quantity is not available
    price: price
    proceed_to_checkout: proceed to checkout
    your_shopping_bag: your shopping bag
  it:
    add_to_bag: aggiungi alla shopping bag
    available: disponibile
    categories: categorie
    continue_shopping: continua lo shopping
    days: giorni
    free_over: gratis oltre
    languages:
      en-US: inglese
      it: italiano
    method: metodo
    out_of_stock: la quantità richiesta non è disponibile
    price: prezzo
    proceed_to_checkout: vai al checkout
    your_shopping_bag: la tua shopping bag
```

``` shell
$ bundle exec jekyll serve
```

# Deploy

``` shell
$ git init
$ touch .gitignore
```

``` txt
# .gitignore
.DS_Store
_site
```


- Create a Github repo
-

- Create free account on Netlify
