%w(abf.rosalinux.ru abf.io).each do |domain|

  SitemapGenerator::Sitemap.create(
    default_host:   "https://#{domain}",
    sitemaps_path:  "sitemaps/#{domain}"
  ) do

    # root
    add(root_path)

    # Projects
    Project.opened.find_each do |project|
      add(project_path(project), lastmod: project.updated_at)
    end

    # BuildLists
    BuildList.for_status(BuildList::BUILD_PUBLISHED).
      where(platforms: { visibility: 'open' }, projects: { visibility: 'open' }).
      joins(:save_to_platform, :project).
      find_each do |bl|
        add(build_list_path(bl), lastmod: bl.updated_at)
    end

    # Platforms
    Platform.opened.find_each do |platform|
      add(platform_path(platform), lastmod: platform.updated_at)

      # Repositories
      add(platform_repositories_path(platform), lastmod: platform.updated_at)
      platform.repositories.find_each do |repository|
        add(platform_repository_path(platform, repository), lastmod: repository.updated_at)
      end


      # Products
      add(platform_products_path(platform), lastmod: platform.updated_at)
      platform.products.find_each do |product|
        add(platform_product_path(platform, product), lastmod: product.updated_at)

        # ProductBuildList (ISO)
        product.product_build_lists.for_status(ProductBuildList::BUILD_COMPLETED).find_each do |pbl|
          add(platform_product_product_build_list_path(platform, product, pbl), lastmod: pbl.updated_at)
        end
      end
    end

    # Users
    User.find_each do |user|
      add(user_path(user), lastmod: user.updated_at)
    end

    # Groups
    Group.find_each do |group|
      add(group_path(group), lastmod: group.updated_at)
    end

  end
end