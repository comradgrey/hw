file(GLOB images *.png)

install(FILES
    theme.cfg
    ${images}
    DESTINATION ${SHAREPATH}Data/Themes/Jungle)
