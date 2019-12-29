package agf.icons {
	import flash.display.Sprite;

	public class IconCursorSize extends Sprite {
		public function IconCursorSize() {
			draw();
		}

		private function draw(): void {
			graphics.clear();
			graphics.beginFill(0xff9900);
			graphics.drawRect(0, 0, 8, 8);
			graphics.endFill();
		}

	}
}