<catalog>		"id" - required, free text
				"classname" - required, name of Delphi class that should handle this data
				if classname is not registerd in Delphi, this can be an ActiveX classid

<names>			"full" - required, free text
            	"short" - optional, free text; defaults to the same as "full" if not provided
				"author" - optional, free text;
				"publisher" - optional, free text;

<edition>		"caption" - required, free text
				"copyright" - required, free text
				"published" - required, free text (date)

<language>		"id" - required, free text
				"encoding" - required if "id" is Arabic, free text
				"codepage" - optional, not used yet

<summary>		well-formed HTML providing an overview of the contents of the data

<comments>		"type" - optional, one of "user" or "author"
				"user" comments can be viewed by the user, "author" comments can not
				comments are in well-formed HTML

<permissions>	"copy" - required, one of "yes" or "no" to allow copy to clipboard
				"print" - required, one of "yes" or "no" to allow printing


<navigation>	"viewer" - optional, one of "none", "html", "htmlcombo", "list", or "listcomb"; defaults to "none"
                "style" - optional, one of "none", "book", "page", or "article"

<content>		"type" - required, free text
				"subtype" - optional, free text
  <home>                "href" - optional, free text complete reference including id
                        "name" - the title of the home page
                        "addr" - the internal address of the home page
  <page>        "tag" - optional, the page tag; defaults to "article"
                "attr" - optional, the attribute name; defaults to "title"
                "name" - optional, the page hint/name; defaults to "Article"
                "browse" - optional, one of "yes" or "no"; defaults to "yes"
                "menus" - optional, one of "yes" or "no"; defaults to "no"
                "tabs" - optional, one of "yes" or "no"; defaults to "no"
  <item>        "tag" - optional, the item tag; defaults to "section"
                "attr" - optional, the attribute name; defaults to "heading"
                "name" - optional, the item hint/name; defaults to "Section"
                "browse" - optional, one of "yes" or "no"; defaults to "yes"
                "menus" - optional, one of "yes" or "no"; defaults to "no"
                "split" - optiona, one of "yes" or "no"; defaults to "yes"
                "tabs" - optional, one of "yes" or "no"; defaults to "no"
  <???>         content tag has child tags that are specific to the content type's catalogging requirements


<indexes>
  <index>		"name" - required, one of "fulltext", "subjects", "hrefs", or "inversesubjects"
				"state" - optional, one of "on" or "off"; defaults to "on"


<shortcuts>		"type" - required, one of "internal" (to data) or "external" (to data), or "bookmarks"
				internal shortcuts are like icons within a book, external shortcuts are icons
				placed in Application menu bars and such
  <category>                    "name" - required, free text
  <shortcut>	"caption" - optional, free text; defaults to same as "href"
				"href" - optional, must point to a complete internal or external address including book id (like 'id:xyz'); defaults to home page
				"iconsrc" - optional, must point to an internal or external icon
				"smalliconsrc" - optional, must point to an internal external icon
				"sortkey" - optional, free text; defaults to "caption"
				"keyaccel" - optional, keyboard accelerator in Delphi string form
				"iconidx" - optional, numeric value of an existing Alim ImageList entry
				"smalliconidx" - optional, numeric value of an existing Alim ImageList entry
				"break" - optional, "yes" or "no" value indicating a break after the shortcut (line or otherwise)
				"breakbefore" - optional, "yes" or "no" value indicating a break before the shortcut (line or otherwise)

<build>
  <option>      "fulltextindex" - required, one of "yes" or "no"

<structure>	"id" - optional, free text; defaults to "main"
                this whole tag is normally autogenerated

<customize>		provides default values for customizable actions (source dependent)
  <???>

