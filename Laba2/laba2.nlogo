globals [ max-sheep ]  ; максимальна кількість овець, щоб уникнути надмірного зростання популяції

; Визначаємо окремі породи агентів (вівці і вовки) як підкласи
breed [ sheep a-sheep ]  ; для множини використовується "sheep", для однини - "a-sheep"
breed [ wolves wolf ]

turtles-own [ energy ]       ; і вівці, і вовки мають атрибут енергії
patches-own [ countdown ]    ; змінна для визначення часу росту трави в моделі "вівці-вовки-трава"

to setup
  clear-all
  ifelse netlogo-web? [ set max-sheep 10000 ] [ set max-sheep 30000 ]

  ; Якщо обрано модель з травою, налаштовуємо стан трави на кожній ділянці
  ifelse model-version = "sheep-wolves-grass" [
    ask patches [
      set pcolor one-of [ green brown ] ; випадковий вибір між зеленою (трава) та коричневою (відсутність трави) клітинкою
      ifelse pcolor = green
        [ set countdown grass-regrowth-time ] ; встановлюємо час росту для зеленої ділянки
        [ set countdown random grass-regrowth-time ] ; випадково встановлюємо таймер для коричневої ділянки
    ]
  ]
  [
    ask patches [ set pcolor green ] ; якщо модель без трави, всі клітинки стають зеленими
  ]

  create-sheep initial-number-sheep  ; створюємо початкову кількість овець і налаштовуємо їх атрибути
  [
    set shape  "sheep"
    set color white
    set size 1.5  ; робимо овець більшими для кращої видимості
    set label-color blue - 2
    set energy random (2 * sheep-gain-from-food) ; встановлюємо початкову енергію
    setxy random-xcor random-ycor ; розміщуємо на випадкових координатах
  ]

  create-wolves initial-number-wolves  ; створюємо початкову кількість вовків і налаштовуємо їх атрибути
  [
    set shape "wolf"
    set color black
    set size 2  ; робимо вовків більшими для кращої видимості
    set energy random (2 * wolf-gain-from-food) ; встановлюємо початкову енергію
    setxy random-xcor random-ycor ; розміщуємо на випадкових координатах
  ]
  display-labels ; оновлюємо мітки енергії (якщо обрано їх відображення)
  reset-ticks ; скидаємо лічильник кроків
end

to go
  ; завершення моделі, якщо немає ані вовків, ані овець
  if not any? turtles [ stop ]
  if not any? wolves and count sheep > max-sheep [ user-message "The sheep have inherited the earth" stop ]

  ask sheep [
    move 
    avoid-wolves  ; уникаємо вовків, якщо вони поруч
    ; у цій версії вівці їдять траву, трава росте, а пересування вівці вимагає енергії
    if model-version = "sheep-wolves-grass" [
      set energy energy - 1  ; вівці витрачають енергію на рух
      eat-grass  ; вівці їдять траву
      death ; вівці вмирають від голоду
    ]
    reproduce-sheep ; вівці розмножуються
  ]
  
  ask wolves [
    hunt-sheep  ; полювання на овець з уникненням інших вовків
    set energy energy - 1  ; вовки втрачають енергію на рух
    eat-sheep ; вовки їдять вівцю, якщо вона є на клітинці
    death ; вовки вмирають, якщо енергія закінчується
    reproduce-wolves ; вовки розмножуються
  ]

  if model-version = "sheep-wolves-grass" [ ask patches [ grow-grass ] ]

  remove-excess-wolves  ; видалення зайвих вовків на одній клітинці
  tick ; переходимо до наступного кроку
  display-labels ; оновлюємо мітки енергії
end

to move  ; процедура пересування
  rt random 50 ; повертаємо на випадковий кут до 50 градусів
  lt random 50 ; повертаємо на інший випадковий кут до 50 градусів
  fd 1         ; пересуваємося на одну клітинку вперед
end


; Процедура для вівці, щоб їсти траву з імовірністю смерті 10%
to eat-grass  ; вівця їсть траву і змінює колір клітинки
  if pcolor = green [
    ; З ймовірністю 10% вівця помирає при поїданні трави
    if random-float 100 < 10 [
      die
    ]
    ; Якщо вівця виживає, вона їсть траву, змінює колір клітинки на коричневий і отримує енергію
    set pcolor brown
    set energy energy + sheep-gain-from-food
  ]
end
end

to reproduce-sheep  ; процедура для розмноження овець
  if random-float 100 < sheep-reproduce [  ; ймовірність розмноження
    set energy (energy / 2)                ; ділить енергію між батьком і нащадком
    hatch 1 [ rt random-float 360 fd 1 ]   ; створює нащадка і пересуває його
  ]
end

to reproduce-wolves  ; процедура для розмноження вовків
  if random-float 100 < wolf-reproduce [  ; ймовірність розмноження
    set energy (energy / 2)               ; ділить енергію між батьком і нащадком
    hatch 1 [ rt random-float 360 fd 1 ]  ; створює нащадка і пересуває його
  ]
end

to eat-sheep  ; процедура для вовків
  let prey one-of sheep-here                    ; обирає випадкову вівцю на тій самій клітинці
  if prey != nobody  [                          ; якщо є вівця
    ask prey [ die ]                            ; вівця гине
    set energy energy + wolf-gain-from-food     ; вовк отримує енергію від їжі
  ]
end

to death  ; процедура для вівці та вовка
  ; коли енергія падає нижче нуля, помре
  if energy < 0 [ die ]
end

to grow-grass  ; процедура для росту трави
  ; для коричневих ділянок: якщо лічильник дорівнює нулю, трава виростає
  if pcolor = brown [
    ifelse countdown <= 0
      [ set pcolor green
        set countdown grass-regrowth-time ] ; оновлюємо лічильник росту
      [ set countdown countdown - 1 ]
  ]
end

to-report grass
  ; повертає список зелених ділянок, якщо модель включає траву
  ifelse model-version = "sheep-wolves-grass" [
    report patches with [pcolor = green]
  ]
  [ report 0 ]
end

to display-labels
  ask turtles [ set label "" ]
  if show-energy? [
    ask wolves [ set label round energy ]  ; показуємо енергію вовків
    if model-version = "sheep-wolves-grass" [ ask sheep [ set label round energy ] ] ; показуємо енергію овець
  ]
end

; додавання логіки згідно з варіантом

; Дозволяє вовку знаходити овець поблизу та уникати інших вовків
to hunt-sheep
  let sheep-near one-of sheep in-radius 1  ; знаходить найближчу вівцю в радіусі 1 клітинки
  let wolf-near one-of other wolves in-radius 1  ; перевіряє, чи є інші вовки поруч
  ifelse sheep-near != nobody and wolf-near = nobody [
    face sheep-near fd 1  ; пересувається в напрямку вівці, якщо інших вовків поруч немає
  ]
  [
    if wolf-near = nobody [ rt random 360 fd 1 ]  ; інакше, рухається у випадковому напрямку
  ]
end

; Змушує вівцю рухатися в протилежному напрямку при виявленні вовка поруч
to avoid-wolves
  let wolf-near one-of wolves in-radius 1  ; перевіряє, чи є вовк у радіусі однієї клітинки
  if wolf-near != nobody [
    rt 180  ; повертає вівцю на 180 градусів
    fd 1  ; пересуває її вперед, подалі від вовка
  ]
end

; Видаляє надлишкових вовків на одній клітинці, залишаючи лише одного
to remove-excess-wolves
  ask patches [
    let wolves-here wolves-here  ; отримує всіх вовків на поточній клітинці
    if count wolves-here > 1 [
      ask n-of (count wolves-here - 1) wolves-here [ die ]  ; видаляє всіх вовків, крім одного
    ]
  ]
end


