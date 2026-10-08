@Entry
@Component
struct Index {
  @State message: Resource = $r('app.string.starter_hello');

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('HelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = $r('app.string.starter_welcome');
        })
    }
    .height('100%')
    .width('100%')
  }
}
