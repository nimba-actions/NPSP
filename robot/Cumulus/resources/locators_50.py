from locators_51 import *
import copy

npsp_lex_locators = copy.deepcopy(npsp_lex_locators)
npsp_lex_locators['delete_icon']='//span[contains(text() ,"{}")]/following::span[. = "{}"]/following-sibling::a/child::span[@class = "deleteIcon"]',
npsp_lex_locators['object']['field']= "//div[contains(@class, 'uiInput')][.//label[contains(@class, 'uiLabel')][.//span[text()='{}']]]//*[self::input or self::textarea]",