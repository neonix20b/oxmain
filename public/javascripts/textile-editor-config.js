var teButtons = TextileEditor.buttons;

teButtons.push(new TextileEditorButton('ed_strong',			'bold.png',          '*',   '*',  'b', 'Жирный','s'));
teButtons.push(new TextileEditorButton('ed_emphasis',		'italic.png',        '_',   '_',  'i', 'Наклонный','s'));
teButtons.push(new TextileEditorButton('ed_underline',	'underline.png',     '+',   '+',  'u', 'Подчеркнутый','s'));
teButtons.push(new TextileEditorButton('ed_strike',     'strikethrough.png', '-',   '-',  's', 'Зачеркнутый','s'));
teButtons.push(new TextileEditorButton('ed_ol',					'list_numbers.png',  ' # ', '\n', ',', 'Нумерованный список'));
teButtons.push(new TextileEditorButton('ed_ul',					'list_bullets.png',  ' * ', '\n', '.', 'Маркированный список'));
teButtons.push(new TextileEditorButton('ed_p',					'paragraph.png',     'p',   '\n', 'p', 'Абзац'));
teButtons.push(new TextileEditorButton('ed_h1',					'h1.png',            'h1',  '\n', '1', 'Заголовок 1'));
teButtons.push(new TextileEditorButton('ed_h2',					'h2.png',            'h2',  '\n', '2', 'Заголовок 2'));
teButtons.push(new TextileEditorButton('ed_h3',					'h3.png',            'h3',  '\n', '3', 'Заголовок 3'));
teButtons.push(new TextileEditorButton('ed_h4',					'h4.png',            'h4',  '\n', '4', 'Заголовок 4'));
teButtons.push(new TextileEditorButton('ed_block',   		'blockquote.png',    'bq',  '\n', 'q', 'Цитата'));
teButtons.push(new TextileEditorButton('ed_outdent', 		'outdent.png',       ')',   '\n', ']', 'Увеличить отступ'));
teButtons.push(new TextileEditorButton('ed_indent',  		'indent.png',        '(',   '\n', '[', 'Уменьшить отступ'));
teButtons.push(new TextileEditorButton('ed_justifyl',		'left.png',          '<',   '\n', 'l', 'Выровнять по левому краю'));
teButtons.push(new TextileEditorButton('ed_justifyc',		'center.png',        '=',   '\n', 'e', 'Выровнять по центру'));
teButtons.push(new TextileEditorButton('ed_justifyr',		'right.png',         '>',   '\n', 'r', 'Выровнять по правому краю'));
teButtons.push(new TextileEditorButton('ed_justify', 		'justify.png',       '<>',  '\n', 'j', 'Выровнять по ширине'));
teButtons.push(new TextileEditorButton('ed_more', 		'more.png',       ' --- ',  '\n', 'm', 'Разделитель - \'Читать далее\''));

// teButtons.push(new TextileEditorButton('ed_code','code','@','@','c','Code'));