use cosmic::{
    Element, Task,
    app::{self, Core},
};
use std::process::Command;

const ID: &str = "org.chaoskarsten.CosmicAppletShowDesktop";
const ICON: &str = "user-desktop-symbolic";

struct Window {
    core: Core,
}

#[derive(Clone, Debug)]
enum Message {
    Toggle,
}

impl cosmic::Application for Window {
    type Executor = cosmic::SingleThreadExecutor;
    type Flags = ();
    type Message = Message;
    const APP_ID: &'static str = ID;

    fn core(&self) -> &Core {
        &self.core
    }

    fn core_mut(&mut self) -> &mut Core {
        &mut self.core
    }

    fn init(core: Core, _flags: Self::Flags) -> (Self, app::Task<Self::Message>) {
        (Self { core }, Task::none())
    }

    fn update(&mut self, message: Self::Message) -> app::Task<Self::Message> {
        match message {
            Message::Toggle => {
                let home = std::env::var("HOME").unwrap_or_default();
                let _ = Command::new(format!("{home}/.local/bin/show-desktop")).spawn();
            }
        }
        Task::none()
    }

    fn view(&self) -> Element<'_, Self::Message> {
        self.core
            .applet
            .icon_button(ICON)
            .on_press_down(Message::Toggle)
            .into()
    }

    fn style(&self) -> Option<cosmic::iced::theme::Style> {
        Some(cosmic::applet::style())
    }
}

fn main() -> cosmic::iced::Result {
    cosmic::applet::run::<Window>(())
}
