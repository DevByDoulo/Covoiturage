import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ConfirmationDeconnexion } from './shared/ui/confirmation-deconnexion';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, ConfirmationDeconnexion],
  template: '<router-outlet /><app-confirmation-deconnexion />',
})
export class App {}
