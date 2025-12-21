extends TabContainer

func log(tab: RichTextLabel, text: String):
	tab.text += '\n'
	tab.text += text
	tab.text += '\n'
