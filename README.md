# HitGroup-Informer-HUD
Плагин предоставляет информацию по всем частям тела после смерти или каждого попадания.

## Требования
 - ПЛАГИН РАБОТАЕТ ТОЛЬКО НА CS:GO

## Установка
- Скомпилировать и переместить в папку addons/sourcemod/plugins/
* Конфиг сгенерируется сам: cfg/hud_hitgroups.cfg можете настроить его по желанию

## Переменные
- **hg_output_type** - Режим отображения [0 - после попадания | 1 - после смерти] | **default: 1**
- **hg_holdtime** - Время отображения | **default: 3.0**
- **hg_x** - Позиция по X [От 0.0 до 1.0 | -1.0 - центр] | **default: 0.05**
- **hg_y** - Позиция по Y [От 0.0 до 1.0 | -1.0 - центр] | **default: 0.5**
- **hg_allinfo** - Тип отображения [0 - выводить только попадания по частям тела | 1 - выводить всю информацию] | **default: 1**
- **hg_hud_color** - Цвет худа RGB [0-255 0-255 0-255] | **default: 0 255 0**
- **hg_method** - Метод отображения [0 - HUD | 1 - Hint (сверху)] | **default: 0**
- **hg_hint_hit_color** - Цвет отметки попадания HEX | **default: FF0000**
- **hg_hint_casual_color** - Стартовый цвет мест попаданий HEX | **default: 00FF00**
- **hg_count_hit** - Покраска всей части тела, без вывода счетчиков [0 - да | 1 - нет] | **default: 1**

## Если вы заметили баг или ошибку - напишите мне: 
- Quake#2601 - DISCORD
- [HLMOD](https://hlmod.ru/members/palonez.92448/)
- [STEAM](https://steamcommunity.com/id/comecamecame/)
