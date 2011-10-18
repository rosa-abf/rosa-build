class Permission < ActiveRecord::Base
  belongs_to :role
  def name
    Permission.right(self.right_id)
  end
  def self.get_rights_list
    res=[]
    for k in 1..8
      res << [Permission.right(k), k]
    end
    return res
  end
  def self.right(n)
    case n
    when 1
      "Проекты - Чтение"
    when 2
      "Проекты - Чтение/Запись"
    when 3
      "Проекты - Сборка"
    when 4
      "Репозиторий - Просмотр"
    when 5
      "Репозиторий - Изменение состава пакетов"
    when 6
      "Платформа - Создание/Удаление репозиториев"
    when 7
      "Платформа - Изменение параметров платформы"
    when 8
      "Платформа - Сборка"
    end
  end
end