ActiveAdmin.register FlashNotify do
  permit_params :body_ru, :body_en, :status, :published

  menu parent: 'Misc'

  index do
    column :id
    column(:body_en) do |fn|
      fn.body_en.truncate(18)
    end
    column(:body_ru) do |fn|
      fn.body_ru.truncate(18)
    end
    column :published

    actions
  end

  form do |f|
    f.inputs do
      f.input :body_en
      f.input :body_ru
      f.input :status, as: :select, collection: FlashNotify::STATUSES, include_blank: false
      f.input :published
    end
    f.actions
  end

end
