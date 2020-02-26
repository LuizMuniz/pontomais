#########################################################################################################################################################
jvn4F9TY$N&#(VNx23@M5
#########################################################################################################################################################
git status
git checkout --ours www
git add www
git status
git commit -m "Merge master"
#########################################################################################################################################################
#Esse arquivo contem os scripts utilizados em algumas tarefas de CES e ficarão salvos para eventuais consultas
#No caso abaixo, o cliente antes de fazer o reset de conta exportou os pontos que estavam no sistema em vários arquivos, com isso duplicou
#o NSR, foi necessário pegar os pontos que não estavam processados, criar um novo relógio no sistema para pegar o ID e depois migrar os pontos não 
#processados para esse relógio novo, e depois mandar processar
#O comando abaico criou a variavel tcdus e pegou todos os pontos que não estavam processados no periodo  
tcdus = TimeCard::Untreated.where(time_clock_id: 38840, processed: false).order(:time_clock_sequence_number).between('2019-07-23', '2019-08-03')
#O camando abaixo cuspiu os dados para verificarmos se estava tudo certo
tcdus.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number, :processed)
#Depois verificar quatos pontos serão processados
tcdus.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number, :processed).length
#Agora é necessário interar ponto a ponto para dar um update no time_clock_id:
tcdus.each_with_index.map do |tcdu, index|
    tcdu.update_columns(time_clock_id: 41012)
end
#Depois que atualizou os ID, é necessário atualizar a tcdus com os pontos novamente, porém agora no novo id
tcdus = TimeCard::Untreated.where(time_clock_id: 41012, processed: false).order(:time_clock_sequence_number).between('2019-07-23', '2019-08-03')

#Agora é só processar os pontos
tcdus.each_with_index.map do |tcdu, index|
    tcdu.process || tcdu.time_card.errors.messages
end

c.each_with_index.map do |s, index|
    f = s.report_layouts
end

Client.joins(:report_layouts).where(report_layouts: { software: 8 }).count


#########################################################################################################################################################
#O Script abaixo foi utilizado na atualização de turno da Gaby, pois ela estava com o turno errado
#Primeiro colocamos a Pontomais em uma variavel
c = Client.find 3
#Depois colocamos a gaby em uma variavel
e = Employee.find 358191
#Colocamos o turno dela em outra
s = e.shift_id
e.shift_changes
#Atualizamos o turno e o updated_at
e.update_columns(shift_id: s.id, updated_at: Time.now)
#Verificamos as alterações
e.shift_changes
#fizemos um teste com apenas uma alteração de turno
e.shift_changes.first
#Jogamos essa alteração de turno em uma variavel
sc = e.shift_changes.first
#Atualizamos o shift_idst
#Atualizamos o shift_id e o updated_at dessa alteração de turno
sc.update_columns(shift_id: s.id, updated_at: Time.now)
#Verificamos o total de pontos dela
e.work_days.count
#Not aimportante, sempre verificar se o colaborador tem fechamentos, caso ele tenha não pode mexer
e.work_days.closed.count
#Nesse caso ela não tinha, então pegamos o workday dela
wd = e.work_days.last
wd.simulate_preprocess
wds = e.work_days
#Depois pegas os workdays dela e repete o processo
wds.each_with_index.map do |wd, index|
    print("\r#{index} | #{wds.length} | #{wd.date}      ")
    wd.simulate_preprocess
end

wds.each_with_index.map do |wd, index|
    print("\r#{index} | #{wds.length} | #{wd.date}      ")
    wd.process
end

wds.each_with_index.map do |wd, index|
    print("\r#{index} | #{wds.length} | #{wd.date}      ")
    wd.simulate_process
end

wds.each_with_index.map do |wd, index|
    print("\r#{index} | #{wds.length} | #{wd.date}      ")
    wd.process(false)
end

wds = e.work_days.order(:date)
wds.first.process
#########################################################################################################################################################
wds = e.work_days.order(:date)
wds.each_with_index.map do |wd, index|
    print("#{wd.date} | #{wd.time_balance_humanize}")
end

print("#{index} | #{wd.date} | #{wd.time_balance} | #{\r}")
wds.last.time_balance_entries.last.signed_amount_humanized
#########################################################################################################################################################
#Esse script abaixo foi utilizado para verificar o que estava ocorrendo com um saldo do colaborador, pois foi feito um debito manual, e o sistema debitou duas vezes
#Primeiro coloquei o colaborador em uma variavel
e = Employee.find 232036
#Depois peguei os work_days dele
wds = e.work_days.order(:date)
#peguei só os dois dias com problema
wds = e.work_days.between('2019-08-16', '2019-08-17')
#Simulei o processamento, nota, o & executa o comando para todos os itens da lista, sem precisar colocar no each_with_index.map
wds.map(&:simulate_process)
#peguei o lançamento manual do banco dela
wds.last.time_balance_entries
#Pra ver o valor do lançamento humanizado é só pedir com o metodo humanize
wds.last.time_balance_entries.last.signed_amount_humanized
#Peguei o lançamento do dia 17 que é onde estava o problema e joguei dentro de uma variavel
lwd = wds.last
#Foi necessário passar o metodo que calcula o saldo linha a linha para identuificar o erro, o metodo def set_time_balance no work_day.rb
#Criamos a variavel start_date e colocamos as preferencias do cliente para o dia nela
start_date = client_preference_data&.compensatory_time_off&.start_date
keep_previous_time_balance = lwd.shift&.cumulative_extra_time || !lwd.client_preference_data&.compensatory_time_off&.enabled || (start_date && lwd.date < start_date)
#Pegamos o saldo dele
previous_time_balance = TimeCard::WorkDay.by_employee_id(e.id).find_by(date: (lwd.date - 1.day))&.time_balance || 0
time_balance_entries_sum = lwd.time_balance_entries.map(&:signed_amount).sum
lwd.time_balance += time_balance_entries_sum
#Pelo fato do metodo ser protected tem que passar ele com o .send
lwd.send :set_ignored_from_time_balance
#########################################################################################################################################################

e.time_cards.where(date: '2019-08-25').map do |tc|
    [
        tc.datetime,
        tc.id,
        tc.untreated_id,
        tc.untreated&.created_at,
        tc.untreated&.software_method_humanize,
        tc.disabled,
        tc.register_type_humanize
    ]
end

#########################################################################################################################################################

wtc.each_with_index.map do |tc , index|
    tc.update_columns(deleted_at: Time.now)
end
#########################################################################################################################################################
Employee.with_deleted.with_inactive.find_by_email('arthur.pucci@zup.com.br')
User.with_deleted.with_inactive.find_by_email('arthur.pucci@zup.com.br')
Employee.unscoped.find_by_user_id(423561)
#########################################################################################################################################################
 e.work_days.order(:date).map do |wd|
    puts [
        I18n.l(wd.date),
        I18n.l(wd.updated_at),
        I18n.t(wd.processed),
        I18n.t(wd.closed),
        wd.time_balance_humanize,
    ].to_csv
end

#########################################################################################################################################################

client = Client.find e.client_id
employees = client.employees

employees.time_cards.order(:date.)map do |tc|
    [
        tc.date,
        tc.time,
        tc.register_type,
    ]
    #print("#{index} | #{wd.date} | #{wd.auto_interval} | #{\r}")
end

employees.order(:date).after('2019-09-05').map do |timecards|
    [
        wd.date,
        wd.time,
        wd.register_type,
    ]
end

#########################################################################################################################################################
employee = Employee.find 332957
client = Client.find employee.client_id
shifts = client.shifts.order(:updated_at)
shifts.pluck(:id, :parent_id, :name, :created_at, :updated_at, :auto_interval, :active)
timecards = employee.time_cards.with_deleted.order(:date).after('2019-08-31')
timecards.pluck(:date, :created_at, :updated_at, :register_type)
workdays = employee.work_days.order(:date)


#########################################################################################################################################################

pegar o colaborador
pegar o workday e verificar pelo workday quando deveria ter sido gerado o intervalo

#########################################################################################################################################################

es.map do |employee|
  [
    wd = employee.work_days.where(date: '2019-10-31'),
    wd.process
  ]
end

wds.each_with_index.map do |wd, index|
    print("\r#{index} | #{wds.length} | #{wd.date}")  
    wd.process
end  

e = Employee.find 495184
c = Client.find e.client_id
es = c.employees

es.each_with_index.map do |e, index|
    wds = e.work_days.before(e.initial_date)
    wds.update_all(deleted_at: Time.now)
end

#########################################################################################################################################################

e.work_days.where(date: "2019-10-16").map do |wd|
    puts [
        I18n.l(wd.date),
        wd.total_time_humanize,
        wd.extra_time_50_percent_humanize,
    ]
end
total_time: 27840.0,
  regular_time: 27840.0,
  extra_time_50_percent: 60.0,
  extra_time_100_percent: 0.0,

#########################################################################################################################################################
#Para apagar os arquivos no servidor
rm 000*.txt

#########################################################################################################################################################
#Script utilizado para recalcular toda a base da cliente para atualizar o saldo de banco

e = Employee.find 509285
c = Client.find e.client_id
wd = e.work_days.where(date: "2019-09-20").first

wd.each_with_index.map do |w, i|

wd.simulate_preprocess
wd.simulate_process
wd.process

wd.update_time_balance(false)

#########################################################################################################################################################

e = Employee.find 509285
c = Client.find e.client_id
wds = e.work_days.order(:date)

wds.each_with_index.map do |wd, index|
    print("\n #{index} | #{wd.date} | #{wd.time_balance}")
    wd.simulate_preprocess
    wd.simulate_process
    wd.process
    print("\n #{index} | #{wd.date} | #{wd.time_balance}")
end

#########################################################################################################################################################

e = Employee.find 509285
c = Client.find e.client_id
wd = e.work_days.order(:date)

es = c.employees.order(:first_name)

es.each_with_index.map do |e, i|
    wds = e.work_days.order(:date).first
    wds.simulate_preprocess
    wds.simulate_process
    wds.process
    print("\n #{i} | #{wds.date} | #{wds.employee_id} | #{wds.time_balance}")
end

#########################################################################################################################################################

tcdus.each_with_index.map do |tc, index|
  tc.process
  print("#{index} | time_Cards.errors.messages")
end 

#########################################################################################################################################################
j.each_with_index.map do |jb, i|
    jb.date = "2019-03-01"  
    jb.save  
    jb.errors
end  

wd.each_with_index.map do |w, i|
  w.simulate_preprocess
  w.simulate_process
  w.process
end

#########################################################################################################################################################

wd = e.work_days.order(:date).after('2019-10-01')
wd.each_with_index.map do |w, i|
    [
        w.date,
        w.shift_day_id
    ]
end

#########################################################################################################################################################
e = Employee.find 236001
se = e.shift_exemptions.where(date: '2019-08-06')
se.each_with_index.map do |exemption, index|
    exemption.answered_by_id = 251129
    exemption.answered_at = Time.now
    exemption.solicitation_status = 3
    exemption.save
end
wd = e.work_days.where(date: '2019-07-09')
wd.each_with_index.map do |w, i|
    w.simulate_preprocess
    w.simulate_process
    w.process
    w.errors
end

#########################################################################################################################################################

e = Employee.find 349983
c = Client.find e.client_id

es = c.employees.order(:first_name)
es.each_with_index.map do |e, i|
    [
        tcds = e.time_cards.where(register_type: 4).order(:date),
        y = tcds.pluck(:employee_id, :date, :time),
        print("\n #{y}")
]
end

s.each_with_index.map do |e, i|
      wds = e.work_days.first
      wds.simulate_preprocess
      wds.simulate_process
      wds.process
    end 
#########################################################################################################################################################

ids = wds.map(&:employee_id)

#pegar a data do workday e a data do ultimo fechamento do colaborador

lcd = es.each_with_index.map do |e, i|
  [
    e.id, 
    e.last_closed_date,
    wds = es.each_with_index.map do |e, i| e.work_days.where(process_status: 4) end.flatten
    wdids = wds.map(&:id)
    wds = TimeCard::WorkDay.where(id: wdids).open
    wdd = wds.map(&:date),
  ]  
end  
    
lcd = wds.each_with_index.map do |wd, i|
    ld = wd.employee.last_closed_date
    [
        wd.id,
        wd.date,
        ld, 
        wd.date <= ld
    ]
end

wkd = es.each_with_index.map do |es, i|
    wds = es.work_days.where(date: '2019-10-31')
end

wkd.each_with_index.map do |w, i|
    w.process
end

es.each_with_index.map do |e, i|
    wd = e.work_days.where(date: '2019-11-01')
    wd.map(&:process)
end

es.map(&:work_days).where

ids = es.map(&:id)
wds = TimeCard::WorkDay.where(id: ids, date: '2019-10-31')

wds = es.work_days.where(date: '2019-10-31')

#########################################################################################################################################################
# Esse treco aqui é importante, ele mostra todas as alterações feitas no cadastro do colaborador nos ultimos 10 dias :)
e.versions.map(&:changeset)
s = e.shift
s.family_tree
#########################################################################################################################################################
#TODO - Incluir uma tela similar a de reset de conta que omatheus fez, para o histórico de alterações de turnos

#########################################################################################################################################################
#                       SCRIPT PARA REMOVER PONTOS PRÉ-ASSINALADOS, EXECUTADO PARA UM ÚNICO COLABORADOR                                                 #
#########################################################################################################################################################


employee = Employee.find 349983
client = Client.find employee.client_id
work_day = employee.work_days.where(date: '2019-10-21').first

time_cards_to_reprocess = employee.time_cards.where(register_type: 4).order(:date, :time).flatten

work_day_to_be_processed_ids = employee.time_cards.where(register_type: 4).order(:date, :time).pluck(:work_day_id)

work_day_to_be_processed_ids.count
time_cards_to_reprocess.count
employee.last_closed_date

work_day_to_be_processed = TimeCard::WorkDay.where(id: work_day_to_be_processed_ids)

employee.last_closed_date

has_days_with_proposals = TimeCard::WorkDay.where(id: work_day_to_be_processed).joins(:proposals)

errors = []

work_day_to_be_processed.each_with_index.map do |work_day, index|   
    is_open = !work_day.employee.last_closed_date || work_day.date > work_day.employee.last_closed_date
    if is_open && work_day.proposals.empty?
        employee_time_cards = work_day.time_cards.where(register_type: 4)
        employee_time_cards.update_all(deleted_at: Time.now)
        work_day.update_columns(process_status: 2)
        work_day.process || work_day.errors.messages
    else
        errors << work_day.errors.messages
    end
end

#########################################################################################################################################################
#                       SCRIPT PARA REMOVER PONTOS PRÉ-ASSINALADOS, EXECUTADO PARA TODA A BASE DO CLIENTE                                               #
#########################################################################################################################################################

client = Client.find 42652
employees = client.employees.order(:first_name, :last_name)

time_cards_to_reprocess = []

employees.each_with_index.map do |time_card, index|
    time_cards_to_reprocess << time_card.time_cards.where(register_type: 4)
end

work_day_to_be_processed_ids = []

employees.each_with_index.map do |time_card, index|
    work_day_to_be_processed_ids << time_card.time_cards.where(register_type: 4).pluck(:work_day_id).flatten
end

work_day_to_be_processed_ids.count
time_cards_to_reprocess.count

work_day_to_be_processed = TimeCard::WorkDay.where(id: work_day_to_be_processed_ids)
work_day_to_be_processed.count

has_days_with_proposals = TimeCard::WorkDay.where(id: work_day_to_be_processed).joins(:proposals)
has_days_with_proposals.count

process_errors = []
errors = []

work_day_to_be_processed.each_with_index.map do |work_day, index|   
    is_open = !work_day.employee.last_closed_date || work_day.date > work_day.employee.last_closed_date
    if is_open && work_day.proposals.empty?
        employee_time_cards = work_day.time_cards.where(register_type: 4)
        employee_time_cards.update_all(deleted_at: Time.now)
        work_day.update_columns(process_status: 2)
        work_day.process || work_day.errors.messages
        print("\n#{index} | #{work_day.date} | #{work_day.employeqe_id}")

    else
        print("\n#{index} | #{work_day.date} | #{work_day.employee_id} | #{is_open.inspect} | #{work_day.proposals.empty?.inspect}")
    end
end

#########################################################################################################################################################

tcdus = TimeCard::Untreated.where(time_clock_id: 1751).order(:date).after('2018-09-27')
#O camando abaixo cuspiu os dados para verificarmos se estava tudo certo
tcdus.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number, :processed)
#Depois verificar quatos pontos serão processados
tcdus.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number, :processed).length
#Agora é necessário interar ponto a ponto para dar um update no time_clock_id:
tcu_ids = []
tcdus.each_with_index.map do |tcdu, index|
    tcdu.update_columns(time_clock_id: 51374, updated_at: Time.now)
    tcu_ids << tcdu.id
    print("\r#{index} | #{tcdu.date}      ")
end

tcu_ids.count

tcds = TimeCard.where(untreated_id: tcu_ids).order(:date)
tcds.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number)
tcds.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number).length

tcds.each_with_index.map do |tc, index|
    tc.update_columns(time_clock_id: 51374, updated_at: Time.now)
    print("\r#{index} | #{tc.date}      ")
end

tcds = TimeCard::Untreated.where(time_clock_id: 51374).order(:date)
tcds.each_with_index.map do |tc, index|
    print("\r#{index} | #{tc.date}      ")
    tc.process || tc.time_card.errors.messages
end

#########################################################################################################################################################

employee = Employee.find 565808
client = Client.find employee.client_id

employees = client.employees

employees.count

work_days_to_be_processed = []

employees.each_with_index.map do |employee, index|
    work_days = employee.work_days.where(process_status: 4).order(:date)
    work_days_to_be_processed << work_days
end

work_days_to_be_processed.count

work_days_to_be_processed.each_with_index.map do |work_day, index|
    work_day.process
    print("\n #{index} | #{work_days_to_be_processed.length} | #{work_day.erros}")
end

#########################################################################################################################################################

employee = Employee.find 565808
client = Client.find employee.client_id

employees = client.employees.order(:first_name, :last_name)

employees.count

work_day_to_be_processed_ids = []

employees.each_with_index.map do |employee, index| 
    work_days = employee.work_days.where(process_status: 4).order(:date)
    work_day_to_be_processed_ids << work_days.ids
end

work_day_to_be_processed_ids.length

work_day_to_be_processed = TimeCard::WorkDay.where(id: work_day_to_be_processed_ids)

work_day_to_be_processed.length #377

work_day_to_be_processed.each_with_index.map do |work_day, index|
    work_day.process
    print("\n #{index} | #{work_day_to_be_processed.length} | #{work_day.errors.messages}")
end



tc = TimeCard.where(id: work_day_to_be_processed_ids)
ids = []

tc.each_with_index.map do |t, i|
    id = t.employee_id
    ids << id
end

es = Employee.where(id: ids).order(:first_name)


pegar todos os dias qu ele tempo 
darta de inicio
movimentação de cargo
work day

#########################################################################################################################################################

employee = Employee.find 565816
client = Client.find employee.client_id

employees = client.employees.order(:first_name, :last_name)

employees.count

work_days_to_be_removed = []
time_cards_to_be_removed = []

employees.each_with_index.map do |e, i|
    wd = e.work_days.before(employee.initial_date.-1.day)
    
    wd.each_with_index.map do |w, i|
        w.update_columns(deleted_at: Time.now)
    end
    tc = e.time_cards.before(employee.initial_date.-1.day)

    tc.each_with_index.map do |w, i|
        w.update_columns(deleted_at: Time.now)
    end
end


#É bem simples de fazer, basta deles os work_days e timecards antes da data inicial dos colaboradores
#Amanhã de manhã eu faço isso, porque vai ser lindo de resolver esse BO :)



#########################################################################################################################################################

e = Employee.find 38140
se = e.shift_exemptions.where(date: '2019-08-06')
se.each_with_index.map do |exemption, index|
    exemption.answered_by_id = 251129
    exemption.answered_at = Time.now
    exemption.solicitation_status = 3
    exemption.save
end
wd = e.work_days.where(date: '2019-07-09')
wd.each_with_index.map do |w, i|
    w.simulate_preprocess
    w.simulate_process
    w.process
    w.errors
end

#########################################################################################################################################################

class ShiftExemption < ActiveRecord::Base
    
    self.table_name = :shift_exemptions


end

new_exemption = ShiftExemption.new(
    date: "2018-02-12",
    client_id: e.client_id,
    employee_id: 38140,
    observation: "Abono",
    status_id: 316481,
    exemption_type: Shift::ExemptionType::ADMINISTRATIVE,
    answered_at: Time.now,
    answered_by_id: 38241,

)

new_exemption.save


another_exemption = ShiftExemption.new(
    date: "2018-02-14",
    client_id: e.client_id,
    employee_id: 38140,
    end_time: "18:00",
    observation: "Abono",
    status_id: 316481,
    start_time: "13:01",
    exemption_type: Shift::ExemptionType::ADMINISTRATIVE,
    answered_at: Time.now,
    answered_by_id: 38241,

)

another_exemption.save

#########################################################################################################################################################
#Essa consulta é por colaborador, caso na consulta haja workdays de mais de um colaborador não vai funcionar
#O Argumento (false) serve para não atualizar o banco de horas na consulta, pra ir mais rápido, ai no final, é só chamar o wd.first.process, que o sistema atualiza o banco dali pra frente
e = Employee.find 38146

wd = e.work_days.after('2017-01-04').order(:date)

wd.each_with_index.map do |w, i|
    w.process(false)
    print("\n #{i} | #{wd.length}")
end  

wd.first.process

#########################################################################################################################################################
e = Employee.find 328890
wds = e.work_days.after('2019-10-01')
wds.count

up = []
prop = []
pl = []

wds.each_with_index.map do |w, i|
    up << w.updated_at
    prop << w.proposals
    pl << w.process_log
end

print("\n #{up} | #{prop} | #{pl}")

#########################################################################################################################################################

e  = Employee.find 328890
wds = e.work_days.after('2019-10-01')
wds.count

values = []

wds.each_with_index.map do |wd, i|
    if wd.proposals.first.status.status_type != 1 && wd.proposals.first.status.status_type != 2 && wd.proposals.first.status.status_type != 3
        puts "chegou"
    else
        puts "não chegou"
    end
end

#########################################################################################################################################################

e = Employee.find 210115
c = Client.find e.client_id
u = c.root_user.employee.id

wd = e.work_days.find_by(date: '2018-11-13')

class ShiftExemption < ActiveRecord::Base
    
    self.table_name = :shift_exemptions


end

new_exemption = ShiftExemption.new(
    date: "2018-11-13",
    client_id: e.client_id,
    employee_id: 210115,
    observation: "Problemas com ponto",
    status_id: 223962,
    exemption_type: Shift::ExemptionType::ADMINISTRATIVE,
    answered_at: Time.now,
    answered_by_id: 161511,

)

new_exemption.save
wd.exemption.answered_by_id = u

#########################################################################################################################################################

e = Employee.find 515070
e.initial_date
wd = e.work_days.find_by(date: '2019-09-27')
wd = e.work_days.with_deleted.find_by(date: '2019-09-27')
wd.proposals
proposal = wd.proposals
proposal.each_with_index.map do |p, i|
  p.update_columns(deleted_at: Time.now, updated_at: Time.now)
end  

#########################################################################################################################################################

e = Employee.find 515070
c = Client.find e.client_id
es = c.employees.order(:initial_date)
es.length

wds = []

es.each_with_index.map do |e, i|
    wds << e.work_days.before(e.initial_date).order(:date)
end  

wds.count

ex = []
prop = []

wds.each_with_index.map do |w, i|
    prop << w.proposals.with_deleted
    ex << w.exemption.with_deleted
end

#########################################################################################################################################################

e = Employee.find 515070
c = Client.find e.client_id
es = c.employees.order(:first_name)
es.length

ex = []
prop = []


es.each_with_index.map do |e, i|
    wd =  e.work_days.with_deleted
    wd.each_with_index.map do |w, i|
        if w.date < e.initial_date
            ex << w.exemption
            prop << w.proposals
            print("\n#{i} | #{wd.length}")
        end
    end
end

ex.count
prop.count

deleted_at_exemption = []
deleted_at_proposals = []

ex.each_with_index.map do |e, i|
    e.each_with_index.map do |exem, i|
        if exemp.present?
            deleted_at_exemption << exem.deleted_at
        end
    end
end

prop.each_with_index.map do |p, i|
    p.each_with_index.map do |pro, i|
        if pro.present?
            deleted_at_proposal << prop
        end
    end
end

#########################################################################################################################################################

ids.each do |item|
  puts item.to_csv
end  

#########################################################################################################################################################


e = Employee.find 536471
c = Client.find e.client_id

bu = BusinessUnit.find 182585

team_ids = bu.teams.pluck(:id)

es = Employee.where(team_id: team_ids).order(:first_name)
es.count

wds = []

es.each_with_index.map do |e, i|
    wds << e.work_days.after("2019-10-15")
end

wds.length

wds.each_with_index.map do |wd, i|
    wd.each_with_index.map do |w, i|
        w.simulate_preprocess
        print("\n#{i}")
    end
end

wds.each_with_index.map do |wd, i|
    wd.each_with_index.map do |w, i|
        w.simulate_process
        print("\n#{i}")E
    end
end

wds.each_with_index.map do |wd, i|
    wd.each_with_index.map do |w, i|
        w.process
        print("\n#{i}")
    end
end

#########################################################################################################################################################s

w.each_with_index.map do |wd, i|
    wd.process
    print("\n#{i} | #{wds.length}")
end

#########################################################################################################################################################

 es.each_with_index.map do |e, i|
    wjt << e if e.job_title_id != e.job_title_changes.last.id
 end  
    
#########################################################################################################################################################

e = Employee.find 38140
e.last_closed_date
c = Client.find e.client_id
u = c.root_user.employee.id

wd = e.work_days.find_by(date: '2017-03-01')

class ShiftExemption < ActiveRecord::Base

    self.table_name = :shift_exemptions
end

new_exemption = ShiftExemption.new(
    date: "2017-03-01",
    client_id: e.client_id,
    employee_id: 38140,
    observation: "Feriado carnaval",
    exemption_type: Shift::E
    emptionType::ADMINISTRATIVE,
    end_time: "18:00",
    is_medical_certificate: false,
    start_time: "14:00",
    status_id: 316481
)

new_exemption.save
wd.exemption_id = new_exemption.id



new_exemption.answered_at = Time.now
answered_by_id: ,

#########################################################################################################################################################
# - Email: gabriel.hinrichs@yara.com
# - Client_id: 110822
# - BusinessUnitId(CIP): 129392
# - BusinessUnitId(CMISS): 129393
# - BusinessUnitId(ESP): 129394
# - 
# - 

c = Client.find 110822

bu = BusinessUnit.find 129392
es = bu.employees.where(initial_date: '2019-12-16').order(:first_name)
es.size

es.pluck(:id, :first_name, :initial_date)

wds = []

es.each_with_index.map do |e, i|
    wd = e.work_days.where(date: '2019-12-13', closed: false).order(:date)
    wds << wd
end.flatten

wds.count

wds.each_with_index.map do |wd, i|
    wd.simulate_preprocess
    wd.simulate_process
    wd.process
    print("\r #{i} | #{wds.count} | #{wd.errors.messages}")
end

es.each_with_index.map do |e, i|
    e.initial_date = '2019-12-13'
    e.save
    print("\r #{i} | #{es.count}")
end

wds.each_with_index.map do |wd, i|
    wd.simulate_preprocess
    wd.simulate_process
    wd.process
    print("\r #{i} | #{wds.count} | #{wd.errors.messages}")
end

es.each_with_index.map do |e, i|
    e.initial_date = '2019-12-16'
    e.save
    print("\r #{i} | #{es.count}")
end

wds.each_with_index.map do |wd, i|
    wd.simulate_preprocess
    wd.simulate_process
    wd.process
    print("\r #{i} | #{wds.count} | #{wd.errors.messages}")
end

#########################################################################################################################################################
# - Email: gabriel.hinrichs@yara.com
# - Client_id: 110822
# - BusinessUnitId(CIP): 129392 - OK
# - BusinessUnitId(CMISS): 129393 - OK
# - BusinessUnitId(ESP): 129394

bu = BusinessUnit.find 129394
es = bu.employees.order(:first_name)
es.size


wds = []
es.each_with_index.map do |e, i|
    wd = e.work_days.before(e.initial_date).where(closed: false).order(:date)
    wds << wd
end.flatten
wds.size
wds.flatten!.compact!
wds.size

wdids = []
wds.each_with_index.map do |wd, i|
    wdids << wd.id
end
wdids.size


tcds = TimeCard.where(work_day_id: wdids)
tcds.size

wds.each_with_index.map do |wd, i|
    wd.update_columns(deleted_at: Time.now)
    print("\r #{i} | #{wds.count}")
end

tcds.each_with_index.map do |tc, i|
    tc.update_columns(deleted_at: Time.now)
    print("\r #{i} | #{wds.count}")
end

es.each_with_index.map do |e, i|
    wd = e.work_days.order(:date).first
    wd.process
    print("\r #{i} | #{es.count}")
end

#########################################################################################################################################################

u = UserIndication.find 11210
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 4247
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 9857
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 10187
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 5435
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 7976
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 4841
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 11012
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 6953
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 11310
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 11309
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 10319
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 11375
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 10715
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 10814
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 7151
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 11969
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 11441
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 12134
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 12299
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 12563
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 12728
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 12365
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 12431
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 12860
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 12893
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan
u = UserIndication.find 12662
u.unscoped_indicated_by_client.name
u.unscoped_indicated_by_client.email
u.unscoped_indicated_by_client.plan

#########################################################################################################################################################
#CES-2393

tcdus = TimeCard::Untreated.where(time_clock_id: 26624).order(:date).before('2020-01-08')
tcdus.count
#26561
#O camando abaixo cuspiu os dados para verificarmos se estava tudo certo
tcdus.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number, :processed)
#Depois verificar quatos pontos serão processados
tcdus.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number, :processed).length
#Agora é necessário interar ponto a ponto para dar um update no time_clock_id:
tcu_ids = []
tcdus.each_with_index.map do |tcdu, index|
    tcdu.update_columns(time_clock_id: 65102, updated_at: Time.now)
    tcu_ids << tcdu.id
    print("\r#{index} | #{tcdu.date}      ")
end

tcdus.count
tcu_ids.count

tcds = TimeCard.where(untreated_id: tcu_ids).order(:date)
tcds.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number)
tcds.pluck(:date, :time, :time_clock_id, :time_clock_sequence_number).length
#25835

tcds.each_with_index.map do |tc, index|
    tc.update_columns(time_clock_id: 65102, updated_at: Time.now)
    print("\r#{index} | #{tc.date}  | #{tcds.count}    ")
end

tcds = TimeCard::Untreated.where(time_clock_id: 26624).order(:date)
tcds.count
tcds.each_with_index.map do |tc, index|
    print("\r#{index} | #{tc.date}      ")
    tc.process || tc.time_card.errors.messages
end

#########################################################################################################################################################

clients = Client.where(plan: 1)
clients.count

clients.each_with_index.map do |c, i|
    puts [
        c.id,
        c.billing_name,
        c.billing_email,
        c.phone,
        c.email,
        c.name,
        c.plan_signed_at,
        c.employees_count,
        c.root_user&.email,
        c.last_user_sign_in_at
].to_csv
end
