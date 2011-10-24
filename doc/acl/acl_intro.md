КРАТКОЕ ОПИСАНИЕ ACL
====================

Предназначение
--------------

ACL предназначена для контроля прав пользователя на выполнение действий в 
системе доступа к моделям по областям видимости. 

Возможности
-----------

*  Неограниченное количество моделей, над которыми могут выполняться
   действия (`target`);
*  Неограниченное количество моделей, которые могут выполнять действия над
   другими (`acter`);
*  Геренатор прав основывающийся на структуре приложения (см. далее);
*  Неограниченное количество ролей, которые могут назначаться для `acter` и
   содержать любую комбинацию прав и доступных видимостей;
*  Объединение прав `acter`-ов на глубину одной модели (см. далее);
*  Разграничение назначения ролей по классам (не завершено, на данный
   момент не критично);
*  Разграничение ролей на глобальные и локальные (см. далее);

Типы моделей
------------

*  __Acter__ - модель, которая может выполнять действия, разрешенные ролями,
   над другими моделями;
*  __Target__ - модель, над которой могут выполняться действия, разрешенные
   ролями;

Генератор прав
--------------

Генератор ролей является Rake-task-ом и запускается командой
`rake rights:generate`.

Желательно запускать после добавления нового метода в контроллер для того,
чтобы на этот метод в системе появилось право.

Задание областей видимости моделей
----------------------------------
*Этот функционал скорее всего будет изменяться*

Если модель должна иметь несколько областей видимости, нужно сделать следующее:

*  Добавить в модель константу `VISIBILITIES`, в которой задать названия областей
   видимости;
*  Добавить к таблице моделей поле `visibility:text`;
*  Добавить `attr_accessible :visibility` в модель; 
*  Создать `scope :by_visibility`, принимающий аргументом массив областей 
   видимости;

После выполнения этих действий на странице редактирования роли появится поле 
выбора областей видимости для этой модели.

Пример:

    model VisibilitiesExample < ActiveRecord::Base
      VISIBILITIES = ['open', 'hidden', 'open_for_admins']
      attr_accessible :visibility

      scope :by_visibility, lambda {|v| {:conditions => ['visibility in (?)', v]}}
    end

Задание типа модели
-------------------
*Этот функционал скорее всего будет изменяться*

Если модель должна иметь возможность быть связанной с другими с использованием 
ролей, необходимо произвести следующие действия:

*  Добавить в модель декларацию `relationable`, с аргументом `:as`, который
   может принимать заначения из `[:object, :target]`. Если модель будет 
   __acter__-ом, передается `:object`, иначе `:target`
   Пример: `relationable :as => :object`
*  Добавить в модель связь `belongs_to :global_role, :class_name => 'Role'`
*  Добавить в модель связь с моделью `Relation`
*  Если модель -- __acter__ и она должна использовать как свои роли, так и
   роли из другой модели, необходимо добавить декларацию `inherit_rights_from`
   которой аргументом присвоить имя/имена связей с моделями, из которых должны
   браться роли.

Примеры:

*  Модель, являющаяся __acter__:

        class ActerModel < ActiveRecord::Base
          relationable :as => :object

          belongs_to :global_role, :class_name => 'Role'
          has_many :targets, :as => :object, :class_name => 'Relation'
        end
*  Модель, являющаяся __acter__ и наследующая права другой модели:

        class ActerWithInheritableRolesModel < ActiveRecord::Base
          relationable :as => :object
          ingerit_rights_from :another_acter_model

          has_many :another_acters_models

          belongs_to :global_role, :class_name => 'Role'
          has_many :targets, :as => :object, :class_name => 'Relation'
        end
*  Модель, являющаяся __target__:

        class TargetModel < ActiveRecord::Base
          relationable :as => :target

          has_many :objects, :as => :target, :class_name => 'Relation'
        end
*  Модель, являющаяся и __acter__, и __target__:

        class ActerAndTargetModel < ActiveRecord::Base
          relationable :as => :object
          relationable :as => :target

          belongs_to :global_role, :class_name => 'Role'
          has_many :targets, :as => :object, :class_name => 'Relation'
          has_many :objects, :as => :target, :class_name => 'Relation'
        end

API для работы с ACL
--------------------
*Этот функционал скорее всего будет изменяться*

### Методы потомков `ActiveRecord::Base`

*  Методы классов:
   -  `relationable` -- устанавливает, кем является модель (acter/target)
   -  `relationable?` -- может ли иметь связь с ролью/ролями с другими
   -  `relation_acters` -- список моделей, которые могут иметь роли по отношению к другим (след. метод)
   -  `relation_targets` -- список моделей, над которыми могут совершаться действия
   -  `relation_acter? (model)`, `relation_target? (model)` -- является ли тем или другим
   -  `inherit_rights_from (:relation_name | [:relation_names])` -- права из каких связанных моделей наследовать
   -  `visible_to (model)` -- все видимые для модели записи, может включаться в цепочку (например, для paginate)

*  Методы инстансов:
   -  `add_role_to(acter, role)` -- привязать acter-а с ролью к текущей записи
   -  `add_role_on(target, role)` -- привязать текущую модель с ролью
   -  `roles_to(object)` -- если object == :system, возвращает глобальные роли текущей записи, если передана запись -- то роли текущей модели над записью
   -  `rights_to(object)` -- аргументы те же, но возвращается список прав, собранный из всех ролей
   -  `right_to(controller_name, action)` -- возвращает запись с правом на выполнение действия action в контроллере c именем controller_name
   -  `can_perform? (controller_name, action, target = :system)` -- показывает, может ли текущая модель выполнить действие контроллера над целью

### Методы потомков `ActiveController::Base`
  - `can_perform? (target = :system)` -- может ли current_user выполнить текущее действие
  - `check_global_rights` -- делает редирект назад, если пользователь вообще не может совершить текущее действие
  - `roles_to(object)` -- возвращает список ролей current_user-а по отношению к объекту
  - `rights_to(object)` -- возвращает список прав current_user-а по отношению к объекту

