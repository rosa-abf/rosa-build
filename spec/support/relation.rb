def create_relation(target, actor, role)
  target.relations.create!(actor: actor, role: role)
end

def create_actor_relation(target, actor, role)
  target.actors.create!(actor: actor, role: role)
end
