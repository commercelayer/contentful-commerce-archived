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

``` shell
$ gem install contentful_bootstrap
$ contentful_bootstrap update_space <YOUR_SPACE_ID> -j path/to/content_model.json
```

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

gem "jekyll"

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
    <link rel="shortcut icon" type="image/x-icon" href="/assets/images/favicon.png" />
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
      {{ site.t[page.locale]['shipping_to'] | capitalize }}:&nbsp;
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
      {{ site.t[page.locale]['language'] | capitalize }}:&nbsp;
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
  <div class="column is-half-tablet is-one-fifth-desktop">
    <h2 class="has-text-weight-bold">{{category.name}}</h2>
    <div class="category-listing box">
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
    language: language
    languages:
      en-US: english
      it: italian
    method: method
    out_of_stock: the requested quantity is not available
    price: price
    proceed_to_checkout: proceed to checkout
    select_size: select your size
    shipping_to: shipping to
    your_shopping_bag: your shopping bag
  it:
    add_to_bag: aggiungi alla shopping bag
    available: disponibile
    categories: categorie
    continue_shopping: continua lo shopping
    days: giorni
    free_over: gratis oltre
    language: lingua
    languages:
      en-US: inglese
      it: italiano
    method: metodo
    out_of_stock: la quantità richiesta non è disponibile
    price: prezzo
    proceed_to_checkout: vai al checkout
    select_size: select your size
    shipping_to: spedizione
    your_shopping_bag: la tua shopping bag

```

``` shell
$ bundle exec jekyll serve
```

# First deploy

``` shell
$ git init
$ touch .gitignore
```

``` txt
# .gitignore
.DS_Store
_site
```

``` shell
$ git add .
$ git commit -m "Initial commit."
$ git tag -a v1.0 -m "Catalogue"
```

- Create a Github repo

``` shell
$ git remote add origin https://github.com/commercelayer/contentful-commerce.git
$ git push -u origin master
```

- Create free account on Netlify
- Connect repo and deploy (link to preview)

# Add ecommerce

``` shell
$ npm init
$ npm install commercelayer --save
$ npm install webpack webpack-cli --save-dev
$ touch webpack.config.js
```

``` js
// webpack.config.js
const path = require('path')

module.exports = {
  mode: 'production',
  entry: './index.js',
  output: {
    filename: 'main.js',
    path: path.resolve(__dirname, "assets/javascripts")
  }
}
```

- Add build and watch scripts to package.json

``` json
{
  "name": "contentful-commerce",
  "version": "1.0.0",
  "description": "Static site e-commerce demo with Contentful, Commerce Layer and Jekyll.",
  "main": "index.js",
  "dependencies": {
    "commercelayer": "^1.1.0"
  },
  "devDependencies": {
    "webpack": "^4.19.1",
    "webpack-cli": "^3.1.0"
  },
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "build": "webpack --progress --mode=production",
    "watch": "webpack --progress --watch"
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/commercelayer/contentful-commerce.git"
  },
  "author": "Filippo Conforti",
  "license": "MIT",
  "bugs": {
    "url": "https://github.com/commercelayer/contentful-commerce/issues"
  },
  "homepage": "https://github.com/commercelayer/contentful-commerce#readme"
}
```

``` shell
$ touch index.js
```

``` js
// index.js

const commercelayer = require('commercelayer')

document.addEventListener('DOMContentLoaded', function () {
  commercelayer.init()
})
```

``` shell
$ touch _includes/commercelayer.html
```

``` html
    <!-- _includes/commercelayer.html -->

    <div id="commercelayer"
      data-base-url="{{site.commercelayer_base_url}}"
      data-client-id="{{site.commercelayer_client_id}}"
      data-market-id="{{page.country.market_id }}"
      data-country-code="{{page.country.code }}"
      data-language-code="{{page.locale}}"
      data-cart-url="{{site.site_base_url}}"
      data-return-url="{{site.site_base_url}}"
      data-privacy-url="{{site.site_base_url}}"
      data-terms-url="{{site.site_base_url}}">
    </div>
```

``` html
    <!-- _layouts/default.html -->

    {% include commercelayer.html %}    
    <script src="/assets/javascripts/main.js"></script>
  </body>
</html>
```

``` shell
$ bundle exec jekyll serve
$ npm run watch
```

- Every change to index js is built as assets/javascripts/main.js

``` txt
# .gitignore
# [...]

node_modules
```

- Add env variables to Netlify
- Commit and push

# Prices

``` html
  <!-- _tamplates/category.html -->

  <div class="price" data-sku-code="{{ product.variants.first.code }}">
    <span class="amount"></span>
    <span class="compare-at-amount"></span>
  </div>
```

``` html
  <!-- _tamplates/product.html -->

<div class="price" data-sku-code="{{ page.product.variants.first.code }}">
  <span class="compare-at-amount large has-text-grey-light"></span>
  <span class="amount large has-text-success"></span>
</div>
```

# Variants

``` html
  <!-- _tamplates/product.html -->

<div class="select is-fullwidth">
  <select class="variant-select">
    <option disabled selected value="">{{ site.t[page.locale]["select_size"] | capitalize }}</option>
    {% for variant in page.product.variants %}
      <option class="variant" data-sku-code="{{variant.code}}">
        {{ variant.size.name }}
      </option>
    {% endfor %}
  </select>
</div>

<a href="#" class="add-to-bag button is-success is-fullwidth" data-product-name="{{page.product.name}}" data-sku-image-Url="{{page.product.image.url}}">
  {{ site.t[page.locale]['add_to_bag'] | capitalize }}
</a>

<div class="available-message has-text-success">
  {{ site.t[page.locale]['available'] | capitalize}} in
  <span class="available-message-min-days"></span>-<span class="available-message-max-days"></span>
  {{ site.t[page.locale]['days'] }}
</div>

<div class="unavailable-message has-text-danger">
  {{ site.t[page.locale]['out_of_stock'] | capitalize }}
</div>
```

# Shopping bag

``` shell
$ touch _includes/shopping_bag_preview.html
$ touch _includes/shopping_bag.html
```

``` html
  <!-- _includes/shopping_bag_preview.html -->

  <a class="navbar-item" id="shopping-bag-toggle">
    <span class="icon">
      <i class="fas fa-shopping-bag"></i>
    </span>
    <span class="tag is-warning is-rounded" id="shopping-bag-preview-count">0</span>
  </a>
```

``` html
  <!-- _includes/shopping_bag.html -->

  <div id="shopping-bag">
    <div class="shopping-bag-content">
      <div class="columns">
        <div class="column">
          <h4 class="has-text-weight-bold">
            {{ site.t[page.locale]['your_shopping_bag'] | capitalize }}
          </h4>
        </div>
        <div class="column">
          <h4 id="shopping-bag-preview-total"></h4>
        </div>
      </div>
      <div class="shopping-bag-unavailable-message has-text-danger">
        {{ site.t[page.locale]['out_of_stock'] | capitalize }}
      </div>
      <table class="table is-fullwidth" id="shopping-bag-table">
      </table>
      <div class="columns">
        <div class="column">
          <a href="#" class="button is-fullwidth" id="shopping-bag-close">
            {{ site.t[page.locale]['continue_shopping'] | capitalize }}
          </a>
        </div>
        <div class="column">
          <a href="#" class="button is-fullwidth is-success" id="shopping-bag-checkout">
            {{ site.t[page.locale]['proceed_to_checkout'] | capitalize }}
          </a>
        </div>
      </div>
    </div>
  </div>
```

``` html
  <!-- _layouts/default.html -->

  <div class="navbar-end">
    <!-- [...] -->
    {% include shopping_bag_preview.html %}
  </div>

  <!-- [...] -->
  </footer>
  {% include shopping_bag.html %}
```
